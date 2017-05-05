/*
 * Copyright (c) 2016 General Electric Company. All rights reserved.
 *
 * The copyright to the computer software herein is the property of
 * General Electric Company. The software may be used and/or copied only
 * with the written permission of General Electric Company or in accordance
 * with the terms and conditions stipulated in the agreement/contract
 * under which the software has been supplied.
 */
 
package com.ge.predix.solsvc.workshop.config;

import java.util.List;

import org.codehaus.jackson.annotate.JsonIgnore;

/**
 * 
 * @author 212546387 -
 */
public class JsonDataNode {
	private String nodeName;
	private String nodeType;
	private int nodePin;
	private String nodePinType;
	private String nodePinDir;
	private String nodeClass;
	@JsonIgnore
	private Short adcAddress;
	@JsonIgnore
	private String expression;
	
	private List<TriggerNode> triggerNodes;
	/**
	 * @return -
	 */
	public String getNodeName() {
		return this.nodeName;
	}
	/**
	 * @param nodeName -
	 */
	public void setNodeName(String nodeName) {
		this.nodeName = nodeName;
	}
	/**
	 * @return -
	 */
	public String getNodeType() {
		return this.nodeType;
	}
	/**
	 * @param nodeType -
	 */
	public void setNodeType(String nodeType) {
		this.nodeType = nodeType;
	}
	/**
	 * @return -
	 */
	public int getNodePin() {
		return this.nodePin;
	}
	/**
	 * @param nodePin -
	 */
	public void setNodePin(int nodePin) {
		this.nodePin = nodePin;
	}
	/**
	 * @return -
	 */
	public String getNodePinType() {
		return this.nodePinType;
	}
	/**
	 * @param nodePinType -
	 */
	public void setNodePinType(String nodePinType) {
		this.nodePinType = nodePinType;
	}
	/**
	 * @return -
	 */
	public String getNodePinDir() {
		return this.nodePinDir;
	}
	/**
	 * @param nodePinDir -
	 */
	public void setNodePinDir(String nodePinDir) {
		this.nodePinDir = nodePinDir;
	}
	/**
	 * @return -
	 */
	public List<TriggerNode> getTriggerNodes() {
		return this.triggerNodes;
	}
	/**
	 * @param triggerNodes -
	 */
	public void setTriggerNodes(List<TriggerNode> triggerNodes) {
		this.triggerNodes = triggerNodes;
	}
	
	/**
	 * @return the adcAddress
	 */
	public Short getAdcAddress() {
		return this.adcAddress;
	}
	/**
	 * @param adcAddress the adcAddress to set
	 */
	public void setAdcAddress(Short adcAddress) {
		this.adcAddress = adcAddress;
	}
	/**
	 * @return the expression
	 */
	public String getExpression() {
		return this.expression;
	}
	/**
	 * @param expression the expression to set
	 */
	public void setExpression(String expression) {
		this.expression = expression;
	}
	public String getNodeClass() {
		return nodeClass;
	}
	public void setNodeClass(String nodeClass) {
		this.nodeClass = nodeClass;
	}

	
}
