<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:import href="xsl-import/imported.xsl" />

<xsl:template match="/">
	<result>
	<xsl:call-template name="test-import" />
	<xsl:for-each select="/table/row/column">
		<column><xsl:attribute name="value"><xsl:value-of select="text()" /></xsl:attribute></column>
	</xsl:for-each>
	</result>
</xsl:template>

</xsl:stylesheet>
