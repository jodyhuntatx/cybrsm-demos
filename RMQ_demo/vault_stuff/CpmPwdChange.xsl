<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:import href='./Syslog/RFC5424Changes.xsl'/>
	<xsl:output method='text' version='1.0' encoding='UTF-8'/>
	<xsl:template match="/">
		<xsl:apply-imports />
		<xsl:for-each select="syslog/audit_record">
{
"action":"<xsl:call-template name="string-replace">
				<xsl:with-param name="from" select="'='"/>
				<xsl:with-param name="to" select="'\='"/>
				<xsl:with-param name="string" select="Action"/>
			</xsl:call-template>
",
"cpmName":"<xsl:call-template name="string-replace">
				<xsl:with-param name="from" select="'='"/>
				<xsl:with-param name="to" select="'\='"/>
				<xsl:with-param name="string" select="Issuer"/>
			</xsl:call-template>
",
"cpmHost":"<xsl:call-template name="string-replace">
				<xsl:with-param name="from" select="'='"/>
				<xsl:with-param name="to" select="'\='"/>
				<xsl:with-param name="string" select="Station"/>
			</xsl:call-template>
",
"cpmMsg":"<xsl:call-template name="string-replace">
				<xsl:with-param name="from" select="'='"/>
				<xsl:with-param name="to" select="'\='"/>
				<xsl:with-param name="string" select="Reason"/>
			</xsl:call-template>
",
"safeName":"<xsl:call-template name="string-replace">
				<xsl:with-param name="from" select="'='"/>
				<xsl:with-param name="to" select="'\='"/>
				<xsl:with-param name="string" select="Safe"/>
			</xsl:call-template>
",
"accountName":"<xsl:call-template name="string-replace">
				<xsl:with-param name="from" select="'='"/>
				<xsl:with-param name="to" select="'\='"/>
				<xsl:with-param name="string" select="File"/>
			</xsl:call-template>
",
"accountUsername":"<xsl:for-each select="CAProperties/CAProperty">
				<xsl:if test="@Name='UserName'">
					<xsl:call-template name="string-replace">
						<xsl:with-param name="from" select="'='"/>
						<xsl:with-param name="to" select="'/='"/>
						<xsl:with-param name="string" select="@Value"/>
					</xsl:call-template>
				</xsl:if>
			</xsl:for-each>
"}
		</xsl:for-each>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>

	<!-- replace all occurences of the character(s) `from'
	     by the string `to' in the string `string'.-->
	<xsl:template name="string-replace" >
		<xsl:param name="string"/>
		<xsl:param name="from"/>
		<xsl:param name="to"/>
		<xsl:choose>
			<xsl:when test="contains($string,$from)">
				<xsl:value-of select="substring-before($string,$from)"/>
				<xsl:value-of select="$to"/>
				<xsl:call-template name="string-replace">
					<xsl:with-param name="string" select="substring-after($string,$from)"/>
					<xsl:with-param name="from" select="$from"/>
					<xsl:with-param name="to" select="$to"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$string"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
