<?xml version="1.0"?>
<!--
//	Copyright 2012 John Luetke
//
//	Licensed under the Apache License, Version 2.0 (the "License");
//	you may not use this file except in compliance with the License.
//	You may obtain a copy of the License at
//
//		http://www.apache.org/licenses/LICENSE-2.0
//
//	Unless required by applicable law or agreed to in writing, software
//	distributed under the License is distributed on an "AS IS" BASIS,
//	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//	See the License for the specific language governing permissions and
//	limitations under the License.
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="html" indent="yes" standalone="yes" />

	<xsl:variable name="packageName" select="//documentation/assembly/@name" />
	
	<xsl:template match="/">
<html>
	<head>
		<title>Package <xsl:value-of select="$packageName"/> </title>
		<style>@import url("csdoc.css");</style>
	</head>
	<body>
		<h1>Package <xsl:value-of select="$packageName"/></h1>
		<xsl:call-template name="namespaceList" />
		<xsl:call-template name="typeList" />
		<hr/>
		<xsl:call-template name="typesForNamespaces" />
	</body>
</html>
	</xsl:template>

	<!-- Generates a UL of unique values for type/@namespace -->
	<xsl:template name="namespaceList">
		<h2>Namespaces</h2>
		<ul>
			<xsl:for-each select="//documentation/assembly/types/type[not(@namespace=following::type/@namespace)]">
				<li>
					<strong>
						<a href="#ns-{@namespace}">
							<xsl:value-of select="@namespace"/>
						</a>
					</strong>
				</li>
			</xsl:for-each>
		</ul>
	</xsl:template>

	<!-- Generates a UL of unique values for type/@name -->
	<xsl:template name="typeList">
		<h2>Types</h2>
		<ul>
			<xsl:for-each select="//documentation/assembly/types/type[not(@name=following::type/@name)]">
				<li>
					<a href="#t-{@namespace}.{@name}">
						<strong>
							<xsl:value-of select="@name"/>
						</strong>
						<em>
							(<xsl:value-of select="@namespace"/>)
						</em>
					</a>
				</li>
			</xsl:for-each>
		</ul>
	</xsl:template>

	<!-- Generates a UL of types for all namespaces -->
	<xsl:template name="typesForNamespaces">
		<xsl:for-each select="//documentation/assembly/types/type[not(@namespace=following::type/@namespace)]">
			<a name="ns-{@namespace}" />
			<h2>
				<xsl:value-of select="@namespace"/>
			</h2>
			<xsl:call-template name="typesForNamespace">
				<xsl:with-param name="ns" select="@namespace" />
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>

	<!-- Generates a UL of types within a namespace -->
	<xsl:template name="typesForNamespace">
		<xsl:param name="ns" />
		<xsl:for-each select="//documentation/assembly/types/type[@namespace=$ns]">
			<a name="t-{$ns}.{@name}" />
			<h3>
				<xsl:value-of select="@name"/>
			</h3>
			<p>
				<xsl:value-of select="./summary"/>
			</p>
			<p>
				<xsl:value-of select="./remarks"/>
			</p>
			<xsl:call-template name="constructorsForType">
				<xsl:with-param name="type" select="@name" />
			</xsl:call-template>
			
			<xsl:call-template name="fieldsForType">
				<xsl:with-param name="type" select="@name" />
			</xsl:call-template>
			
			<xsl:call-template name="methodsForType">
				<xsl:with-param name="type" select="@name" />
			</xsl:call-template>

			<hr/>
		</xsl:for-each>
	</xsl:template>

	<!-- 
	Generates a <p> of fields for a type 
	-->
	<xsl:template name="fieldsForType">
		<xsl:param name="type" />

		<xsl:if test="count(//documentation/assembly/types/type[@name=$type]/fields) &gt; 0">
			<p class="fields">
				<h4>Fields</h4>
				<dl>
					<xsl:for-each select="//documentation/assembly/types/type[@name=$type]/fields/field">
							<dd>
								<code><xsl:value-of select="@name"/></code>
								- <xsl:value-of select="summary/text()" />
							</dd>
					</xsl:for-each>
				</dl>
			</p>
		</xsl:if>
	</xsl:template>

	<!-- 
	Generates a <p> of constructors for a type
	-->
	<xsl:template name="constructorsForType">
		<xsl:param name="type" />

		<xsl:if test="count(//documentation/assembly/types/type[@name=$type]/methods[method/@constructor='true']) &gt; 0">
			<p class="constructors">
				<h4>Constructors</h4>
				<dl>
					<xsl:for-each select="//documentation/assembly/types/type[@name=$type]/methods/method">
						<xsl:variable name="sig">
							<xsl:call-template name="signatureForMethod">
								<xsl:with-param name="type" select="$type"/>
								<xsl:with-param name="pos" select="position()"/>
							</xsl:call-template>
						</xsl:variable>
						<dt>
							<code>
								<xsl:value-of select="$sig" />
							</code>
						</dt>
						<dd>
							<xsl:value-of select="summary/text()" />
						</dd>
						<dd>
							<xsl:value-of select="remarks/text()" />
						</dd>
						<xsl:call-template name="parametersForMethod">
							<xsl:with-param name="type" select="$type" />
							<xsl:with-param name="pos" select="position()" />
						</xsl:call-template>
						<xsl:call-template name="exceptionsForMethod">
							<xsl:with-param name="type" select="$type" />
							<xsl:with-param name="pos" select="position()" />
						</xsl:call-template>
						<xsl:call-template name="returnsForMethod">
							<xsl:with-param name="type" select="$type" />
							<xsl:with-param name="pos" select="position()" />
						</xsl:call-template>
					</xsl:for-each>
				</dl>
			</p>
		</xsl:if>
	</xsl:template>

	<!--
	Generates a <dl> structure for parameters of the given method position on the given type
	-->
	<xsl:template name="parametersForMethod">
		<xsl:param name="type" />
		<xsl:param name="pos" />
		<xsl:if test="count(//documentation/assembly/types/type[@name=$type]/methods/method[position()=$pos]/parameters/parameter) &gt; 0">
			<dd class="parameters">
				<dl>
					<dt>Parameters</dt>
					<xsl:for-each select="//documentation/assembly/types/type[@name=$type]/methods/method[position()=$pos]/parameters/parameter">
						<dd>
							<code>
								<xsl:value-of select="@name"/>
							</code>
							- <xsl:value-of select="text()"/>
						</dd>
					</xsl:for-each>
				</dl>
			</dd>
		</xsl:if>
	</xsl:template>

	<!--
	Generates a <dl> structure for exceptions thrown by the given method position on the given type
	-->
	<xsl:template name="exceptionsForMethod">
		<xsl:param name="type" />
		<xsl:param name="pos" />
		<xsl:if test="count(//documentation/assembly/types/type[@name=$type]/methods/method[position()=$pos]/throws/exception) &gt; 0">
			<dd class="exceptions">
				<dl>
					<dt>Throws</dt>
					<xsl:for-each select="//documentation/assembly/types/type[@name=$type]/methods/method[position()=$pos]/throws/exception">
						<dd>
							<code>
								<xsl:value-of select="@type"/>
							</code>
							- <xsl:value-of select="text()"/>
						</dd>
					</xsl:for-each>
				</dl>
			</dd>
		</xsl:if>
	</xsl:template>

	<!--
	Generates a <dl> structure for the return value of the given method position on the given type
	-->
	<xsl:template name="returnsForMethod">
		<xsl:param name="type" />
		<xsl:param name="pos" />
		<xsl:if test="count(//documentation/assembly/types/type[@name=$type]/methods/method[position()=$pos]/return) &gt; 0">
			<dd class="returns">
				<dl>
					<dt>Returns</dt>
					<xsl:for-each select="//documentation/assembly/types/type[@name=$type]/methods/method[position()=$pos]/return">
						<dd>
							<xsl:value-of select="text()"/>
						</dd>
					</xsl:for-each>
				</dl>
			</dd>
		</xsl:if>
	</xsl:template>

	<!-- 
	Generates a <p> of methods for a type 
	-->
	<xsl:template name="methodsForType">
		<xsl:param name="type" />

		<xsl:if test="count(//documentation/assembly/types/type[@name=$type]/methods[method/@constructor='false']) &gt; 0">
			<p class="methods">
				<h4>Methods</h4>
				<dl>
					<xsl:for-each select="//documentation/assembly/types/type[@name=$type]/methods/method">
						<xsl:variable name="sig">
							<xsl:call-template name="signatureForMethod">
								<xsl:with-param name="type" select="$type"/>
								<xsl:with-param name="pos" select="position()"/>
							</xsl:call-template>
						</xsl:variable>
						<dt>
							<code>
								<xsl:value-of select="$sig" />
							</code>
						</dt>
						<dd>
							<xsl:value-of select="summary/text()" />
						</dd>
						<dd>
							<xsl:value-of select="remarks/text()" />
						</dd>
						<xsl:call-template name="parametersForMethod">
							<xsl:with-param name="type" select="$type" />
							<xsl:with-param name="pos" select="position()" />
						</xsl:call-template>
						<xsl:call-template name="exceptionsForMethod">
							<xsl:with-param name="type" select="$type" />
							<xsl:with-param name="pos" select="position()" />
						</xsl:call-template>
						<xsl:call-template name="returnsForMethod">
							<xsl:with-param name="type" select="$type" />
							<xsl:with-param name="pos" select="position()" />
						</xsl:call-template>
					</xsl:for-each>
				</dl>
			</p>
		</xsl:if>
	</xsl:template>

	<!-- 
	Generates a string holding the signature of a method
	-->
	<xsl:template name="signatureForMethod">
		<xsl:param name="type" />
		<xsl:param name="pos" select="1" />

		<xsl:value-of select="concat(//documentation/assembly/types/type[@name=$type]/methods/method[position()=$pos]/@name, ' (')"/>
		<xsl:for-each select="//documentation/assembly/types/type[@name=$type]/methods/method[position()=$pos]/parameters/parameter">
				<xsl:value-of select="@type"/>
				<xsl:value-of select="concat(' ', '')"/>
				<xsl:value-of select="@name"/>
				<xsl:choose>
				<xsl:when test="@order = ../@count">
					<xsl:value-of select="concat('', ')')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat('', ', ')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>

</xsl:stylesheet>
