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
	<xsl:output method="xml" indent="yes" standalone="yes" />
	
	<!-- 
	Given a Fully-qualifed type name (namespace.subspace.subspace.type), returns
	the namespace portion (namespace.subspace.subspace)
	-->
	<xsl:template name="get-namespace">
		<xsl:param name="type" />
		<xsl:param name="ns"></xsl:param>
		<xsl:choose>
			<xsl:when test="contains($type, '.')">
				<xsl:call-template name="get-namespace">
					<xsl:with-param name="type" select="substring-after($type, '.')"/>
					<xsl:with-param name="ns" select="concat($ns, concat(substring-before($type, '.'), '.'))" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="substring($ns, 0, string-length($ns))"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- 
	Given a Fully-qualifed type name (namespace.subspace.subspace.type), returns
	the type portion (type)
	-->
	<xsl:template name="get-typename">
		<xsl:param name="type" />

		<xsl:choose>
			<xsl:when test="contains($type, '.')">
				<xsl:call-template name="get-typename">
					<xsl:with-param name="type" select="substring-after($type, '.')" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$type"/>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

	<!-- 
	Given a string containing a list of delimited tokens, the delimiter, and the 1-based
	position of the token desired, returns that token
	-->
	<xsl:template name="nth-token">
		<xsl:param name="list" />
		<xsl:param name="delimiter" />
		<xsl:param name="n" />
		<xsl:param name="iteration">1</xsl:param>

		<xsl:choose>
			<xsl:when test="$iteration = $n">
				<xsl:if test="contains($list, $delimiter)">
					<xsl:value-of select="substring-before($list, $delimiter)"/>
				</xsl:if>
				<xsl:if test="not(contains($list, $delimiter))">
					<xsl:value-of select="$list"/>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="nth-token">
					<xsl:with-param name="list" select="substring-after($list, $delimiter)"/>
					<xsl:with-param name="delimiter" select="$delimiter"/>
					<xsl:with-param name="n" select="$n"/>
					<xsl:with-param name="iteration" select="$iteration+1"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

	<!-- Matches the root of the C# doc file -->
	<xsl:template match="/">
		<xsl:element name="documentation">
			<xsl:apply-templates select="//assembly" />
		</xsl:element>
	</xsl:template>

	<!-- Matches the assembly node of the C# doc file -->
	<xsl:template match="assembly">
		<xsl:element name="assembly">
			<xsl:attribute name="name">
				<xsl:value-of select="name"/>
			</xsl:attribute>
			<xsl:element name="types">
				<xsl:apply-templates select="//member[contains(@name,'T:')]" />
			</xsl:element>
		</xsl:element>
	</xsl:template>

	<!-- Matches the summary node of the C# doc file -->
	<xsl:template match="summary">
		<xsl:element name="summary">
			<xsl:value-of select="normalize-space(.)"/>
		</xsl:element>
	</xsl:template>

	<!-- Matches the param node of the C# doc file -->
	<xsl:template match="param">
		<xsl:param name="type">UNKNOWN</xsl:param>
		<xsl:param name="types">UNKNOWN</xsl:param>
		<xsl:param name="number">0</xsl:param>

		<xsl:variable name="token">
			<xsl:call-template name="nth-token">
				<xsl:with-param name="list" select="$types" />
				<xsl:with-param name="delimiter">,</xsl:with-param>
				<xsl:with-param name="n" select="$number" />
			</xsl:call-template>
		</xsl:variable>

		<xsl:element name="parameter">
			<xsl:attribute name="name">
				<xsl:value-of select="@name"/>
			</xsl:attribute>
			<xsl:attribute name="type">
				<xsl:value-of select="$token"/>
			</xsl:attribute>
			<xsl:attribute name="order">
				<xsl:value-of select="$number"/>
			</xsl:attribute>
			<xsl:value-of select="normalize-space(.)"/>
		</xsl:element>
	</xsl:template>

	<!-- Matches the returns node of the C# doc file -->
	<xsl:template match="returns">
		<xsl:element name="return">
			<xsl:value-of select="normalize-space(.)"/>
		</xsl:element>
	</xsl:template>

	<!-- Processes member names with the T: prefix, which are types (classes, enums, etc) -->
	<xsl:template match="//member[contains(@name,'T:')]">
		
		<!-- saves the FQTN (fully-qualified type name -->
		<xsl:variable name="fulltypename" select="substring-after(@name, ':')"/>
		<!-- saves the type name -->
		<xsl:variable name="typename">
			<xsl:call-template name="get-typename">
				<xsl:with-param name="type" select="$fulltypename" />
			</xsl:call-template>
		</xsl:variable>
		<!-- saves the types namespace-->
		<xsl:variable name="namespace">
			<xsl:call-template name="get-namespace">
				<xsl:with-param name="type" select="$fulltypename" />
			</xsl:call-template>
		</xsl:variable>

		<!-- create a <type name="??" namespace="??"> element-->
		<xsl:element name="type">
			
			<xsl:attribute name="name">
				<xsl:value-of select="$typename"/>
			</xsl:attribute>
			<xsl:attribute name="namespace">
				<xsl:value-of select="$namespace"/>
			</xsl:attribute>

			<!-- apply any descriptive templates (<summary>, etc) to the type -->
			<xsl:apply-templates/>

			<!-- process the fields of this type. Determined using the FQTN and the F: prefix -->
			<!-- will be enclosed by <fields> -->
			<xsl:if test="//member[contains(@name,concat('F:',$fulltypename))]">
				
				<xsl:element name="fields">
					
					<xsl:for-each select="//member[contains(@name,concat('F:',$fulltypename))]">
						
						<!-- string the namspace and type portions -->
						<xsl:variable name="fieldname" select="substring-after(@name, concat('F:',$fulltypename,'.'))"/>
						
						<!-- if not empty, create a node -->
						<!-- this was put in place because sometimes empty nodes were created. cause not identified. -->
						<xsl:if test="string-length($fieldname) != 0">
							
							<xsl:element name="field">
								<xsl:attribute name="name">
									<xsl:value-of select="$fieldname"/>
								</xsl:attribute>

								<xsl:apply-templates/>

							</xsl:element>
							
						</xsl:if>
						
					</xsl:for-each>
					
				</xsl:element>
				
			</xsl:if>

			<!-- process the properties of this type. Determined using the FQTN and the P: prefix -->
			<!-- will be enclosed by <properties> -->
			<xsl:if test="//member[contains(@name,concat('P:',$fulltypename))]">
				
				<xsl:element name="properties">
					
					<xsl:for-each select="//member[contains(@name,concat('P:',$fulltypename))]">
						
						<!-- string the namspace and type portions -->
						<xsl:variable name="propertyname" select="substring-after(@name, concat('P:',$fulltypename,'.'))"/>

						<!-- if not empty, create a node -->
						<!-- this was put in place because sometimes empty nodes were created. cause not identified. -->
						<xsl:if test="string-length($propertyname) != 0">
							<xsl:element name="property">
								<xsl:attribute name="name">
									<xsl:value-of select="$propertyname"/>
								</xsl:attribute>

								<xsl:apply-templates/>

							</xsl:element>
						</xsl:if>
						
					</xsl:for-each>
					
				</xsl:element>
				
			</xsl:if>

			<!-- process the properties of this type. Determined using the FQTN and the M: prefix -->
			<!-- will be enclosed by <methods> -->
			<xsl:if test="//member[contains(@name,concat('M:',$fulltypename))]">

				<xsl:element name="methods">
					
					<xsl:for-each select="//member[contains(@name,concat('M:',$fulltypename))]">
						
						<!-- saves the method name -->
						<xsl:variable name="methodname" select="substring-before(substring-after(@name, concat('M:',$fulltypename,'.')), '(')"/>
						<!-- save the parameter types for the method -->
						<xsl:variable name="methodparams" select="substring-before(substring-after(substring-after(@name, concat('M:',$fulltypename,'.')), '('), ')')"/>

						<!-- if not empty, create a <method> node -->
						<!-- this was put in place because sometimes empty nodes were created. cause not identified. -->
						<xsl:if test="string-length($methodname) != 0">

							<xsl:element name="method">

								<!-- if the method is a constructor, replace the '#ctor' with the type name -->
								<!-- and set the constructor attribute to true -->
								<xsl:choose>
									
									<xsl:when test="contains($methodname, '#ctor')">
										<xsl:attribute name="name">
											<xsl:value-of select="$typename"/>
										</xsl:attribute>
										<xsl:attribute name="constructor">true</xsl:attribute>
									</xsl:when>
									
									<xsl:otherwise>
										<xsl:attribute name="name">
											<xsl:value-of select="$methodname"/>
										</xsl:attribute>
										<xsl:attribute name="constructor">false</xsl:attribute>
									</xsl:otherwise>
									
								</xsl:choose>

								<!-- summary template should be first -->
								<xsl:apply-templates select="summary"/>

								<!-- process the parameters of this method -->
								<!-- will be enclosed in <paramemters> -->
								<xsl:if test="count(param)!=0">
									
									<xsl:element name="parameters">

										<!-- attribute holding the parameter count -->
										<xsl:attribute name="count">
											<xsl:value-of select="count(param)"/>
										</xsl:attribute>

										<!-- create the <parameter> node(s) -->
										<xsl:for-each select="param">
											<xsl:apply-templates select=".">
												<xsl:with-param name="number" select="position()" />
												<xsl:with-param name="types" select="$methodparams"/>
												<xsl:with-param name="type">System.Object</xsl:with-param>
												<xsl:sort order="ascending" select="order"/>
											</xsl:apply-templates>
										</xsl:for-each>
										
									</xsl:element>

								</xsl:if>

								<!-- If The method returns a value, call the template to format it -->
								<!-- <return>Message here</return> -->
								<xsl:if test="count(returns)!=0">
									<xsl:apply-templates select="returns"/>
								</xsl:if>

								<!-- Exceptions thrown by the method -->
								<xsl:if test="count(exception)!=0">
									<xsl:element name="throws">
										<xsl:apply-templates select="exception"/>
									</xsl:element>
								</xsl:if>

								<!-- usage examples of the method -->
								<xsl:if test="count(example)!=0">
									<xsl:element name="throws">
										<xsl:apply-templates select="example"/>
									</xsl:element>
								</xsl:if>

							</xsl:element>
							
						</xsl:if>
						
					</xsl:for-each>
					
				</xsl:element>
				
			</xsl:if>
			
		</xsl:element>

	</xsl:template>

</xsl:stylesheet>
