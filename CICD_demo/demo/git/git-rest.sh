#!/bin/bash
export APIVERSION="application/vnd.github.v3+json"
export usageMsg="Usage: $0 [ submit | approve | merge | list ] <access-request-filename>"

# Values populated by Summon
export _owner=$OWNER_LOGIN
export botToken=$OWNER_TOKEN
export prReviewerName=$REVIEWER_LOGIN
export prReviewerToken=$REVIEWER_TOKEN

export _repo=policy-ops
export LOGDIR=./logs

main() {
  if [[ $# != 2 ]]; then echo $usageMsg; exit -1; fi
  gitCmd=$1
  case $gitCmd in
    submit | approve | merge | list)
	;;
    *)
	echo ${usageMsg}
	exit -1
  esac
  commitFile=$2

  baseBranch=master
  mergeBranch=$(cat ${commitFile} | jq -r .projectName)
  commitPath="$(date +%Y)/$(date +%m)/$(date +%d)/${mergeBranch}"
  export LOGFILE=${LOGDIR}/${mergeBranch}.log
  touch $LOGFILE

  case $gitCmd in
    submit)
  	createBranch 	  ${_owner} ${_repo} ${baseBranch} ${mergeBranch}
	commitFile 	  ${_owner} ${_repo}               ${mergeBranch} ${commitPath} ${commitFile}
	createPullRequest ${_owner} ${_repo}               ${mergeBranch} ${commitPath} ${commitFile} 
	requestPRReview   ${_owner} ${_repo}               ${mergeBranch} ${commitPath} ${commitFile} 
	;;
    approve)
	createPRReview    ${_owner} ${_repo}               ${mergeBranch} ${commitPath} ${commitFile} 
	;;
    merge)
	mergePullRequest  ${_owner} ${_repo} ${baseBranch} ${mergeBranch} ${commitPath} ${commitFile} 
	;;
    list)
	getCommitMessages ${_owner} ${_repo}               ${mergeBranch} ${commitPath} ${commitFile} 
	;;
    *)
	echo ${usageMsg}
	exit -1
  esac

}

#####################
createBranch() {
  local ownerName=$1; shift
  local repoName=$1; shift
  local baseBranch=$1; shift
  local mergeBranch=$1; shift

  echo "createBranch($baseBranch,$mergeBranch)"

  # get hash of head of base branch
  branch_sha=$(curl -s -X GET \
	-H "Accept: $APIVERSION" \
	https://api.github.com/repos/${ownerName}/${repoName}/git/refs/heads/${baseBranch} \
	| jq -r .object.sha
  )

  if [[ "$branch_sha" == "" ]]; then
    echo "Base branch $baseBranch not found."
    exit -1
  fi

  # create new branch from head of base branch
  createBranchMsg=$(curl -s -X POST			\
	-H "Accept: $APIVERSION"			\
	-H "Authorization: token ${botToken}"		\
	-d "{ 						\
		\"ref\": \"refs/heads/${mergeBranch}\", \
		\"sha\": \"${branch_sha}\" 		\
	    }" 						\
	https://api.github.com/repos/${ownerName}/${repoName}/git/refs
  )

  # update branch protections to require X number of reviews before merge allowed
  # preview feature - hence non-versioned Accept header
  updateBranchMsg=$(curl -s -X PUT					\
	-H "Accept: application/vnd.github.luke-cage-preview+json"	\
	-H "Authorization: token ${botToken}"			\
	-d "{ 							\
		\"required_status_checks\": null,		\
		\"enforce_admins\": null,			\
		\"required_pull_request_reviews\": {		\
		    \"required_approving_review_count\": 1	\
	    	},						\
		\"restrictions\": null,				\
		\"allow_deletions\": true			\
	    }"							\
	https://api.github.com/repos/${ownerName}/${repoName}/branches/${mergeBranch}/protection
  )

  echo >> $LOGFILE
  echo "createBranch($baseBranch,$mergeBranch) =============" >> $LOGFILE
  echo $createBranchMsg | jq . >> $LOGFILE
  echo $updateBranchMsg | jq . >> $LOGFILE
}

#####################
commitFile() {
  local ownerName=$1; shift
  local repoName=$1; shift
  local branchName=$1; shift
  local filePath=$1; shift
  local fileName=$1; shift

  fqFilePath=${filePath}/${fileName}

  echo "commitFile($branchName,$fqFilePath)"

  # get sha of file in branch - if it exists
  file_sha=$(curl -s \
	-H "Accept: $APIVERSION" \
	https://api.github.com/repos/${ownerName}/${repoName}/contents/${fqFilePath}?ref=${branchName} \
	| jq -r .sha
  )

  commit_message="$branchName, $fileName, $(date +%Y-%m-%d/%H:%M:%S)"

  if [[ "${file_sha}" == "" ]]; then
    # create new file
    commitFileMsg=$(curl -s -X PUT					\
	-H "Accept: $APIVERSION"					\
	-H "Authorization: token ${botToken}"				\
	-d "{								\
		\"message\": \"${commit_message}\",			\
		\"content\": \"$(cat ${fileName} | base64 -w 0)\",	\
		\"branch\": \"${branchName}\"				\
	    }"								\
	https://api.github.com/repos/${ownerName}/${repoName}/contents/${fqFilePath}
    )
  else
    # update existing file
    commitFileMsg=$(curl -s -X PUT					\
	-H "Accept: ${APIVERSION}"					\
	-H "Authorization: token ${botToken}"				\
	-d "{								\
		\"message\": \"${commit_message}\",			\
		\"content\": \"$(cat ${fileName} | base64 -w 0)\",	\
		\"sha\": \"${file_sha}\",				\
		\"branch\": \"${branchName}\"				\
	    }"								\
	https://api.github.com/repos/${ownerName}/${repoName}/contents/${fqFilePath}
    )
  fi
  echo >> $LOGFILE
  echo "commitFile($branchName,$fqFilePath) =============" >> $LOGFILE
  echo $commitFileMsg | jq . >> $LOGFILE
}

#####################
getCommitMessages() {
  local ownerName=$1; shift
  local repoName=$1; shift
  local branchName=$1; shift
  local filePath=$1; shift
  local fileName=$1; shift

  http_code=$(curl -s -X GET 		\
	-o /dev/null			\
	-w "%{http_code}\n"		\
	-H "Accept: $APIVERSION"	\
	https://api.github.com/repos/${ownerName}/${repoName}/commits?sha=${branchName} 
  )
  if [[ ${http_code} == 200 ]]; then
    curl -s -X GET 			\
	-H "Accept: $APIVERSION"	\
	https://api.github.com/repos/${ownerName}/${repoName}/commits?sha=${branchName} \
	| jq .[].commit.message | grep ${branchName}
  else
    echo "No commits found for branch ${branchName}."
  fi
}

#####################
createPullRequest() {
  local ownerName=$1; shift
  local repoName=$1; shift
  local branchName=$1; shift
  local filePath=$1; shift
  local fileName=$1; shift

  echo "createPullRequest($branchName,$fileName)"

  pullRequestMsg=$(curl -s -X POST					\
	-H "Accept: ${APIVERSION}"					\
	-H "Authorization: token ${botToken}"				\
	-d "{								\
		\"title\": \"${branchName} project onboarding.\",	\
		\"body\": \"${fileName}\",				\
		\"head\": \"${ownerName}:${branchName}\",		\
		\"base\": \"master\"					\
	    }"								\
	https://api.github.com/repos/${ownerName}/${repoName}/pulls
    )
  echo >> $LOGFILE
  echo "createPullRequest($branchName,$fileName) =============" >> $LOGFILE
  echo $pullRequestMsg | jq . >> $LOGFILE
}

#####################
requestPRReview() {
  local ownerName=$1; shift
  local repoName=$1; shift
  local branchName=$1; shift
  local filePath=$1; shift
  local fileName=$1; shift


  echo "requestPRReview(${branchName},${fileName})"

  pullNumber=$(curl -s -X GET						\
	-H "Accept: ${APIVERSION}" 	  				\
	-H "Authorization: token ${botToken}"				\
	https://api.github.com/repos/${ownerName}/${repoName}/pulls	\
	| jq .[].number
  )
  requestPRReviewMsg=$(curl -s -X POST   		\
	-H "Accept: ${APIVERSION}" 	   		\
	-H "Authorization: token ${botToken}" 		\
	-d "{ 				   		\
		\"reviewers\": [			\
		    \"${prReviewerName}\"		\
		]					\
	    }" 				   		\
	https://api.github.com/repos/${ownerName}/${repoName}/pulls/${pullNumber}/requested_reviewers
  )
  echo >> $LOGFILE
  echo "requestPRReview(${branchName},${fileName}) =============" >> $LOGFILE
  echo ${requestPRReviewMsg} | jq . >> $LOGFILE
}

#####################
createPRReview() {
  local ownerName=$1; shift
  local repoName=$1; shift
  local branchName=$1; shift
  local filePath=$1; shift
  local fileName=$1; shift

  echo "createPullRequestReview(${branchName},${fileName})"

  pullNumber=$(curl -s -X GET 		   				\
	-H "Accept: ${APIVERSION}" 	   				\
	-H "Authorization: token ${prReviewerToken}"			\
	https://api.github.com/repos/${ownerName}/${repoName}/pulls	\
	| jq .[].number
  )
  pullRequestReviewMsg=$(curl -s -X POST   		\
	-H "Accept: ${APIVERSION}" 	   		\
	-H "Authorization: token ${prReviewerToken}" 	\
	-d "{ 				   		\
		\"body\": \"${prReviewerName}\",	\
		\"event\": \"APPROVE\"			\
	    }" 				   		\
	https://api.github.com/repos/${ownerName}/${repoName}/pulls/${pullNumber}/reviews
    )
  echo >> $LOGFILE
  echo "createPullRequestReview(${branchName},${fileName}) =============" >> $LOGFILE
  echo ${pullRequestReviewMsg} | jq . >> $LOGFILE
}

#####################
mergePullRequest() {
  local ownerName=$1; shift
  local repoName=$1; shift
  local baseBranch=$1; shift
  local mergeBranch=$1; shift
  local filePath=$1; shift
  local fileName=$1; shift

  echo "mergePullRequest(${baseBranch},${mergeBranch},${fileName})"

  echo >> $LOGFILE
  echo "mergePullRequest(${baseBranch},${mergeBranch},${fileName}) =============" >> $LOGFILE
  http_code=$(curl -s -X POST       		\
	-o /dev/null				\
	-w "%{http_code}\n"			\
 	-H "Accept: ${APIVERSION}"		\
	-H "Authorization: token ${botToken}"	\
	-d "{					\
	      \"base\": \"${baseBranch}\",	\
	      \"head\": \"${mergeBranch}\",	\
	      \"commit_message\": \"${baseBranch}, ${filePath}, ${fileName}\"   \
	    }"					\
	https://api.github.com/repos/${ownerName}/${repoName}/merges
  )
  case ${http_code} in
    201 | 204)
	echo "Merge successful."
	echo "Merge successful." >> $LOGFILE
	;;
    404)
	echo "Merge branch or base does not exist."
	echo "Merge branch or base does not exist." >> $LOGFILE
	;;
    409)
	echo "Merge conflict, please resolve."
	echo "Merge conflict, please resolve." >> $LOGFILE
	;;
  esac
}

main "$@"
