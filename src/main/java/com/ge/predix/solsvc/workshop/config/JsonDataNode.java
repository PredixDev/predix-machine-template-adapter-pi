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

/**
 * 
 * @author 212546387 -
 */
public class JsonDataNode {
	private String nodeName;
	private String nodeType;
	private int nodePin;
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
	
}
