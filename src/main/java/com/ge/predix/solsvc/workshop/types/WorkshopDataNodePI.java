/*
 * Copyright (c) 2014 General Electric Company. All rights reserved.
 *
 * The copyright to the computer software herein is the property of
 * General Electric Company. The software may be used and/or copied only
 * with the written permission of General Electric Company or in accordance
 * with the terms and conditions stipulated in the agreement/contract
 * under which the software has been supplied.
 */

package com.ge.predix.solsvc.workshop.types;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.UUID;

import org.iot.raspberry.grovepi.GroveDigitalIn;
import org.iot.raspberry.grovepi.GroveDigitalOut;
import org.iot.raspberry.grovepi.devices.GroveLed;
import org.iot.raspberry.grovepi.devices.GroveLightSensor;
import org.iot.raspberry.grovepi.devices.GroveRotarySensor;
import org.iot.raspberry.grovepi.devices.GroveSoundSensor;
import org.iot.raspberry.grovepi.devices.GroveTemperatureAndHumiditySensor;
import org.iot.raspberry.grovepi.pi4j.GrovePi4J;

import com.ge.dspmicro.machinegateway.types.PDataNode;

/**
 * 
 * 
 * @author Predix Machine Sample
 */
public class WorkshopDataNodePI extends PDataNode
{
	private GroveLightSensor lightNode;
	
	private GroveRotarySensor rotaryNode;
	
	private GroveTemperatureAndHumiditySensor tempNode;
	
	private GroveSoundSensor soundNode;
	
	private GroveDigitalIn buttonNode;
	
	private GroveDigitalOut buzzerNode;
	
	private GroveLed ledNode; 
		
    private String nodeType;
    /**
	 * @param machineAdapterId -
	 * @param name -
     * @param nodeType - 
     * @param nodePin -
	 */
	public WorkshopDataNodePI(UUID machineAdapterId, String name,String nodeType,int nodePin) {
		super(machineAdapterId, name);
		this.nodeType = nodeType;
		try {
			GrovePi4J pi = new GrovePi4J();
			switch (this.nodeType) {
			case "Light": //$NON-NLS-1$
				this.lightNode = new GroveLightSensor(pi, nodePin);
				break;
			case "Temperature": //$NON-NLS-1$
				this.tempNode = new GroveTemperatureAndHumiditySensor(pi, nodePin, GroveTemperatureAndHumiditySensor.Type.DHT11);
				break;
			case "Sound": //$NON-NLS-1$
				this.soundNode = new GroveSoundSensor(pi, nodePin);
				break;
			case "RotaryAngle": //$NON-NLS-1$
				this.rotaryNode = new GroveRotarySensor(pi,nodePin);
				this.ledNode = new GroveLed(new GrovePi4J(),3);
				break;
			case "Button": //$NON-NLS-1$
				this.buttonNode = new GroveDigitalIn(pi, nodePin);
				this.buzzerNode = new GroveDigitalOut(pi, 5);	
				break;
			default:
				break;
			}
		} catch (Exception e) {
			throw new RuntimeException("Exception when building the nodes",e); //$NON-NLS-1$
		}
	}

    /**
     * Node address to uniquely identify the node.
     */
    @Override
    public URI getAddress()
    {
        try
        {
            URI address = new URI("sample.subscription.adapter", null, "localhost", -1, "/" + getName(), null, null); //$NON-NLS-1$ //$NON-NLS-2$ //$NON-NLS-3$
            return address;
        }
        catch (URISyntaxException e)
        {
            return null;
        }
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
	public GroveLightSensor getLightNode() {
		return this.lightNode;
	}

	/**
	 * @param lightNode -
	 */
	public void setLightNode(GroveLightSensor lightNode) {
		this.lightNode = lightNode;
	}

	/**
	 * @return -
	 */
	public GroveRotarySensor getRotaryNode() {
		return this.rotaryNode;
	}

	/**
	 * @param rotaryNode -
	 */
	public void setRotaryNode(GroveRotarySensor rotaryNode) {
		this.rotaryNode = rotaryNode;
	}

	/**
	 * @return -
	 */
	public GroveTemperatureAndHumiditySensor getTempNode() {
		return this.tempNode;
	}

	/**
	 * @param tempNode -
	 */
	public void setTempNode(GroveTemperatureAndHumiditySensor tempNode) {
		this.tempNode = tempNode;
	}

	/**
	 * @return -
	 */
	public GroveDigitalIn getButtonNode() {
		return this.buttonNode;
	}

	/**
	 * @param buttonNode -
	 */
	public void setButtonNode(GroveDigitalIn buttonNode) {
		this.buttonNode = buttonNode;
	}

	/**
	 * @return -
	 */
	public GroveDigitalOut getBuzzerNode() {
		return this.buzzerNode;
	}

	/**
	 * @param buzzerNode -
	 */
	public void setBuzzerNode(GroveDigitalOut buzzerNode) {
		this.buzzerNode = buzzerNode;
	}

	/**
	 * @return -
	 */
	public GroveLed getLedNode() {
		return this.ledNode;
	}

	/**
	 * @param ledNode -
	 */
	public void setLedNode(GroveLed ledNode) {
		this.ledNode = ledNode;
	}

	/**
	 * @return -
	 */
	public GroveSoundSensor getSoundNode() {
		return this.soundNode;
	}

	/**
	 * @param soundNode -
	 */
	public void setSoundNode(GroveSoundSensor soundNode) {
		this.soundNode = soundNode;
	}
}
