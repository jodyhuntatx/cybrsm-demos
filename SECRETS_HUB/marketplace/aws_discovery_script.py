#!/usr/bin/env python
# pylint: disable=print-used
import argparse
import os
import sys
from datetime import datetime
from enum import Enum, auto
from os import path
from pathlib import Path

import boto3
from boto3.session import Session
from dateutil.tz import tzlocal


class ClassificationKeys(Enum):
    AWS_MANAGED_SECRETS = auto()
    SECRETS_MANAGED_BY_CYBERARK = auto()
    UNMANAGED_SECRETS = auto()


class Secret:
    # pylint: disable=too-many-instance-attributes, too-many-arguments
    def __init__(self, secret_arn: str, secret_name: str, region: str, created_date: datetime, last_retrived: datetime,
                 last_update: datetime, description: str, kms_key: str, tags: dict):
        self.secret_arn = secret_arn
        self.secret_name = secret_name
        self.region = region
        self.managed_by_cyberark = False
        self.managed_by_aws = False
        self.created_date = str(created_date.date().strftime('%m/%d/%y')) if created_date else None
        self.last_retrived = str(last_retrived.date().strftime('%m/%d/%y')) if last_retrived else None
        self.last_update = str(last_update.date().strftime('%m/%d/%y')) if last_update else None
        self.description = description
        self.used = (datetime.now(tz=tzlocal()) - last_retrived).days <= 60 if last_retrived else False
        self.kms_key = kms_key
        self.tags = tags if tags and len(tags) > 0 else None

    def __str__(self) -> str:
        if self.tags:
            self.tags = str(self.tags).replace(',', ';')
        return ','.join(str(value) for value in self.__dict__.values())

    @classmethod
    def object_titles(cls) -> str:
        titles = [
            'Secret ARN',
            'Secret name',
            'Region',
            'Managed by CyberArk',
            'Managed by AWS',
            'Creation date (UTC)',
            'Last accessed (UTC)',
            'Last updated (UTC)',
            'Description',
            'Used in the last 60 days',
            'KMS Key ID',
            'Tags',
        ]
        return ','.join(titles)


def _convert_aws_secret_to_secret_object(aws_secret: dict, region: str, kms_key_id: str) -> Secret:
    secret_object: Secret = Secret(
        secret_arn=aws_secret.get('ARN'),
        secret_name=aws_secret.get('Name'),
        region=region,
        created_date=aws_secret.get('CreatedDate'),
        last_retrived=aws_secret.get('LastAccessedDate'),
        last_update=aws_secret.get('LastChangedDate'),
        description=aws_secret.get('Description'),
        kms_key=kms_key_id,
        tags=aws_secret.get('Tags'),
    )
    return secret_object


def _save_csv_file(file_name: str, output: str, list_to_export: list) -> None:
    if len(list_to_export) > 0:
        output_path = path.join(output, file_name)
        with open(output_path, 'w', encoding='utf-8') as output_file:
            output_file.write(f'{Secret.object_titles()}{os.linesep}')
            for value in list_to_export:
                output_file.write(f'{value}{os.linesep}')
        print(file_name)


def _get_secret_list(asm_client: boto3):
    response = asm_client.list_secrets()
    secret_list = response['SecretList']

    while 'NextToken' in response:
        next_token = response['NextToken']
        response = asm_client.list_secrets(NextToken=next_token,)
        secret_list.extend(response['SecretList'])

    return secret_list


def _aws_secret_classification(aws_secret: dict, region: str, classification_dict: dict, kms_key_id: str):
    secret_object: Secret = _convert_aws_secret_to_secret_object(aws_secret=aws_secret, region=region, kms_key_id=kms_key_id)
    # Check that the secret is not managed by a rotation lambda
    if not aws_secret.get('RotationEnabled'):
        # Check that the secret is managed by CyberArk
        if secret_object.tags and _is_cyberark_managed(secret_object.tags):
            secret_object.managed_by_cyberark = True
            classification_dict[ClassificationKeys.SECRETS_MANAGED_BY_CYBERARK].append(secret_object)
        else:
            classification_dict[ClassificationKeys.UNMANAGED_SECRETS].append(secret_object)
    else:
        secret_object.managed_by_aws = True
        classification_dict[ClassificationKeys.AWS_MANAGED_SECRETS].append(secret_object)


def _check_permissions_output_destination(output: str, show_errors: bool) -> bool:
    try:
        Path(output).mkdir(parents=True, exist_ok=True)
        return True
    except Exception as ex:
        print(f'Failed to generate reports in {output}.'
              f"\
 Make sure that you have 'write' permissions in this folder and that the folder has free space,"
              f'\
 and then run the script again.')
        if show_errors:
            print(f'Save reports in file system fail. Exception: {ex}', file=sys.stderr)
        return False


def _find_kms_key(asm_client: boto3, secret_id: str):
    response = asm_client.describe_secret(SecretId=secret_id)
    return response.get('KmsKeyId', 'Default')


# pylint: disable=too-many-locals
def scan_aws_account_secrets(output: str, show_errors: bool) -> None:
    if not _check_permissions_output_destination(output=output, show_errors=show_errors):
        sys.exit(1)
    report_file_name = 'SecretsHub_discovery_report.csv'
    aws_session = Session()
    regions = aws_session.get_available_regions('secretsmanager')
    account = boto3.client('sts').get_caller_identity().get('Account')
    classification_dict = {csv_key: [] for csv_key in ClassificationKeys}
    unreached_region = []
    print(f'Started looking for secrets in your account [{account}]. This may take a few minutes')

    # Loop through each region
    for region in regions:
        # Create a Secrets Manager client for the region
        region_client = boto3.client('secretsmanager', region_name=region)
        try:
            print(f'Starting to scan [{region}]...')
            list_secrets = _get_secret_list(region_client)
            for aws_secret in list_secrets:
                secret_name = aws_secret['Name']
                current_secret_kms_key = _find_kms_key(region_client, secret_name)
                _aws_secret_classification(
                    aws_secret=aws_secret,
                    region=region,
                    classification_dict=classification_dict,
                    kms_key_id=current_secret_kms_key,
                )

            print(f'Region [{region}] completed')
        except Exception as ex:
            print(f'Unable to scan region [{region}]. Continuing to the next region.')
            unreached_region.append(region)
            if show_errors:
                print(f'Region [{region}] is inaccessible. Exception: {ex}', file=sys.stderr)

    print(f"Unreached regions: {', '.join(unreached_region)}")
    unmanaged_secrets_count = len(classification_dict[ClassificationKeys.UNMANAGED_SECRETS])
    cyberark_managed_secrets_count = len(classification_dict[ClassificationKeys.SECRETS_MANAGED_BY_CYBERARK])
    aws_managed_secrets_count = len(classification_dict[ClassificationKeys.AWS_MANAGED_SECRETS])
    total_number_of_secrets = unmanaged_secrets_count + cyberark_managed_secrets_count + aws_managed_secrets_count
    managed_secret_count = cyberark_managed_secrets_count + aws_managed_secrets_count
    print(f'Total number of secrets: {total_number_of_secrets}')
    print(f'Total number of secrets not managed by either CyberArk or AWS: {unmanaged_secrets_count}')
    print(f'Total number of secrets managed by CyberArk: {cyberark_managed_secrets_count}')
    print(f'Total number of secrets managed by AWS: {aws_managed_secrets_count}')
    print(f'Percentage of secrets managed by CyberArk and/or AWS: {((managed_secret_count / total_number_of_secrets) * 100):0.2f}%')
    print(f'Percentage of secrets managed by CyberArk: {((cyberark_managed_secrets_count / total_number_of_secrets) * 100):0.2f}%')
    print(f'Summary report is generated under {output}')
    summary_list = []
    for csv_key, item_list in classification_dict.items():
        summary_list.extend(item_list)
    _save_csv_file(report_file_name, output, summary_list)


def _is_cyberark_managed(tags: dict) -> bool:
    for tag in tags:
        if tag.get('Key') == 'Sourced by CyberArk':
            return True
    return False


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--folder_path', default='./', help='The folder path for csv files')
    parser.add_argument('--show-errors', nargs='?', const=True, default=False, help='Show error messages')
    args = parser.parse_args()
    scan_aws_account_secrets(args.folder_path, args.show_errors)
