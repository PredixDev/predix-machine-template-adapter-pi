/*
 * Copyright (c) 2014 General Electric Company. All rights reserved.
 *
 * The copyright to the computer software herein is the property of
 * General Electric Company. The software may be used and/or copied only
 * with the written permission of General Electric Company or in accordance
 * with the terms and conditions stipulated in the agreement/contract
 * under which the software has been supplied.
 */

package com.ge.predix.solsvc.workshop.adapter;

import java.io.File;
import java.io.IOException;
import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Dictionary;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import org.codehaus.jackson.map.ObjectMapper;
import org.codehaus.jackson.type.TypeReference;
import org.iot.raspberry.grovepi.devices.GroveLed;
import org.osgi.service.component.ComponentContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.ge.dspmicro.machinegateway.api.adapter.IDataSubscription;
import com.ge.dspmicro.machinegateway.api.adapter.IDataSubscriptionListener;
import com.ge.dspmicro.machinegateway.api.adapter.IEdgeDataSubscription;
import com.ge.dspmicro.machinegateway.api.adapter.IMachineAdapter;
import com.ge.dspmicro.machinegateway.api.adapter.ISubscriptionAdapterListener;
import com.ge.dspmicro.machinegateway.api.adapter.ISubscriptionMachineAdapter;
import com.ge.dspmicro.machinegateway.api.adapter.MachineAdapterException;
import com.ge.dspmicro.machinegateway.api.adapter.MachineAdapterInfo;
import com.ge.dspmicro.machinegateway.api.adapter.MachineAdapterState;
import com.ge.dspmicro.machinegateway.types.PDataNode;
import com.ge.dspmicro.machinegateway.types.PDataValue;
import com.ge.dspmicro.machinegateway.types.PEnvelope;
import com.ge.predix.solsvc.workshop.config.JsonDataNode;
import com.ge.predix.solsvc.workshop.types.WorkshopDataNodePI;
import com.ge.predix.solsvc.workshop.types.WorkshopDataSubscription;
import com.ge.predix.solsvc.workshop.types.WorkshopSubscriptionListener;

import aQute.bnd.annotation.component.Activate;
import aQute.bnd.annotation.component.Component;
import aQute.bnd.annotation.component.ConfigurationPolicy;
import aQute.bnd.annotation.component.Deactivate;
import aQute.bnd.annotation.component.Modified;
import aQute.bnd.annotation.metatype.Configurable;
import aQute.bnd.annotation.metatype.Meta;

/**
 * 
 * @author Predix Machine Sample
 */
@SuppressWarnings({ "javadoc", "deprecation" })
@Component(name = RaspberryPISubscriptionAdapter.SERVICE_PID, provide =
{
		ISubscriptionMachineAdapter.class, IMachineAdapter.class
}, designate = RaspberryPISubscriptionAdapter.Config.class, configurationPolicy = ConfigurationPolicy.require)
public class RaspberryPISubscriptionAdapter
        implements ISubscriptionMachineAdapter
{
    // Meta mapping for configuration properties
    @Meta.OCD(name = "%component.name", factory=true, localization = "OSGI-INF/l10n/bundle")
    interface Config
    {
        @Meta.AD(name = "%updateInterval.name", description = "%updateInterval.description", id = UPDATE_INTERVAL, required = false, deflt = "")
        String updateInterval();

        @Meta.AD(name = "%nodeConfigFile.name", description = "%nodeConfigFile.description", id = NODE_NAMES, required = false, deflt = "")
        String nodeConfigFile();

        @Meta.AD(name = "%adapterName.name", description = "%adapterName.description", id = ADAPTER_NAME, required = false, deflt = "")
        String adapterName();

        @Meta.AD(name = "%adapterDescription.name", description = "%adapterDescription.description", id = ADAPTER_DESCRIPTION, required = false, deflt = "")
        String adapterDescription();

        @Meta.AD(id = DATA_SUBSCRIPTIONS, name = "%dataSubscriptions.name", description = "%dataSubscriptions.description", required = true, deflt = "")
        String dataSubscriptions();
    }

    /** Service PID for Sample Machine Adapter */
    public static final String                SERVICE_PID         = "com.ge.predix.solsvc.workshop.adapter";         //$NON-NLS-1$
    /** Key for Node Configuration File*/
    public static final String 				  NODE_CONFI_FILE 	  = SERVICE_PID+"configFile";                                    //$NON-NLS-1$
    /** Key for Update Interval */
    public static final String                UPDATE_INTERVAL     = SERVICE_PID + ".UpdateInterval";                             //$NON-NLS-1$
    /** Key for number of nodes */
    public static final String                NODE_NAMES          = SERVICE_PID + ".NodeConfigFile";                              //$NON-NLS-1$
    /** key for machine adapter name */
    public static final String                ADAPTER_NAME        = SERVICE_PID + ".Name";                                       //$NON-NLS-1$
    /** Key for machine adapter description */
    public static final String                ADAPTER_DESCRIPTION = SERVICE_PID + ".Description";                                //$NON-NLS-1$
    /** data subscriptions */
    public static final String                DATA_SUBSCRIPTIONS  = SERVICE_PID + ".DataSubscriptions";                          //$NON-NLS-1$
    /** The regular expression used to split property values into String array. */
    public final static String                SPLIT_PATTERN       = "\\s*\\|\\s*";                                               //$NON-NLS-1$

    public final static String 				  MACHINE_HOME		  = System.getProperty("predix.home.dir"); 					 	 //$NON-NLS-1$
    // Create logger to report errors, warning massages, and info messages (runtime Statistics)
    private static final Logger               _logger             = LoggerFactory
                                                                          .getLogger(RaspberryPISubscriptionAdapter.class);
    private UUID                              uuid                = UUID.randomUUID();
    private Dictionary<String, Object>        props;
    private MachineAdapterInfo                adapterInfo;
    private MachineAdapterState               adapterState;
    private Map<UUID,WorkshopDataNodePI>         dataNodes           = new HashMap<UUID, WorkshopDataNodePI>();

    private int                               updateInterval;

    private Config                            config;

    private static int ADC_REF=5;

    /**
     * Data cache for holding latest data updates
     */
    protected Map<UUID, PDataValue>           dataValueCache      = new ConcurrentHashMap<UUID, PDataValue>();
    private Map<UUID, WorkshopDataSubscription> dataSubscriptions   = new HashMap<UUID, WorkshopDataSubscription>();

    private IDataSubscriptionListener         dataUpdateHandler   = new WorkshopSubscriptionListener();

    /*
     * ###############################################
     * # OSGi service lifecycle management #
     * ###############################################
     */

    /**
     * OSGi component lifecycle activation method
     * 
     * @param ctx component context
     * @throws IOException on fail to load/set configuration properties
     */
    @Activate
    public void activate(ComponentContext ctx)
            throws IOException
    {
        if ( _logger.isDebugEnabled() )
        {
            _logger.debug("Starting sample " + ctx.getBundleContext().getBundle().getSymbolicName()); //$NON-NLS-1$
        }
        
        // Get all properties and create nodes.
        this.props = ctx.getProperties();

        this.config = Configurable.createConfigurable(Config.class, ctx.getProperties());

        this.updateInterval = Integer.parseInt(this.config.updateInterval());
        ObjectMapper mapper = new ObjectMapper();
        File configFile = new File(MACHINE_HOME+File.separator+this.config.nodeConfigFile());
        List<JsonDataNode> nodes = mapper.readValue(configFile, new TypeReference<List<JsonDataNode>>()
        {
            //
        });
        createNodes(nodes);

        this.adapterInfo = new MachineAdapterInfo(this.config.adapterName(),
                RaspberryPISubscriptionAdapter.SERVICE_PID, this.config.adapterDescription(), ctx
                        .getBundleContext().getBundle().getVersion().toString());

        List<String> subs = Arrays.asList(parseDataSubscriptions(DATA_SUBSCRIPTIONS));
        // Start data subscription and sign up for data updates.
        for (String sub : subs)
        {
            WorkshopDataSubscription dataSubscription = new WorkshopDataSubscription(this, sub, this.updateInterval,
                    new ArrayList<PDataNode>(this.dataNodes.values()));
            this.dataSubscriptions.put(dataSubscription.getId(), dataSubscription);
            // Using internal listener, but these subscriptions can be used with Spillway listener also
            dataSubscription.addDataSubscriptionListener(this.dataUpdateHandler);
            new Thread(dataSubscription).start();
        }
    }

    private String[] parseDataSubscriptions(String key)
    {
    	
        Object objectValue = this.props.get(key);
        _logger.info("Key : "+key+" : "+objectValue); //$NON-NLS-1$ //$NON-NLS-2$
        if ( objectValue == null )
        {
            invalidDataSubscription();
        }else {

	        if ( objectValue instanceof String[] )
	        {
	            if ( ((String[]) objectValue).length == 0 )
	            {
	                invalidDataSubscription();
	            }
	            return (String[]) objectValue;
	        }
	
	        String stringValue = objectValue.toString();
	        if ( stringValue.length() > 0 )
	        {
	            return stringValue.split(SPLIT_PATTERN);
	        }
        }
        invalidDataSubscription();
        return new String[0];
    }

    
    private void invalidDataSubscription()
    {
        // data subscriptions must not be empty.
        String msg = "SampleSubscriptionAdapter.dataSubscriptions.invalid"; //$NON-NLS-1$
        _logger.error(msg);
        throw new MachineAdapterException(msg);
    }

    /**
     * OSGi component lifecycle deactivation method
     * 
     * @param ctx component context
     */
    @Deactivate
    public void deactivate(ComponentContext ctx)
    {
        // Put your clean up code here when container is shutting down
        if ( _logger.isDebugEnabled() )
        {
            _logger.debug("Stopped sample for " + ctx.getBundleContext().getBundle().getSymbolicName()); //$NON-NLS-1$
        }

        Collection<WorkshopDataSubscription> values = this.dataSubscriptions.values();
        // Stop random data generation thread.
        for (WorkshopDataSubscription sub : values)
        {
            sub.stop();
        }
        this.adapterState = MachineAdapterState.Stopped;
    }

    /**
     * OSGi component lifecycle modified method. Called when
     * the component properties are changed.
     * 
     * @param ctx component context
     */
    @Modified
    public synchronized void modified(ComponentContext ctx)
    {
        // Handle run-time changes to properties.

        this.props = ctx.getProperties();
    }

    /*
     * #######################################
     * # IMachineAdapter interface methods #
     * #######################################
     */

    @Override
	public UUID getId()
    {
        return this.uuid;
    }

    @Override
	public MachineAdapterInfo getInfo()
    {
        return this.adapterInfo;
    }

    @Override
	public MachineAdapterState getState()
    {
        return this.adapterState;
    }

    /*
     * Returns all data nodes. Data nodes are auto-generated at startup.
     */
    @Override
	public List<PDataNode> getNodes()
    {
        return new ArrayList<PDataNode>(this.dataNodes.values());
    }

    /*
     * Reads data from data cache. Data cache always contains latest values.
     */
    @Override
	public PDataValue readData(UUID nodeId)
            throws MachineAdapterException
    {
        PDataValue pDataValue = new PDataValue(nodeId);
        DecimalFormat df = new DecimalFormat("####.##"); //$NON-NLS-1$
        double fvalue = 0.0f;
        WorkshopDataNodePI node = this.dataNodes.get(nodeId);
		for (int try_num = 1;; try_num++) {
			try {
				switch (node.getNodeType()) {
				case "Light": //$NON-NLS-1$
					fvalue = node.getLightNode().get();
				break;
				case "Temperature": //$NON-NLS-1$
					fvalue = node.getTempNode().get().getTemperature();
					break;
				case "Sound": //$NON-NLS-1$
					fvalue = node.getSoundNode().get();
					break;
				case "RotaryAngle": //$NON-NLS-1$
					double sensorValue = node.getRotaryNode().get().getSensorValue();
					double calculatedValue = Math.round((sensorValue) * ADC_REF / 1023);
					
					fvalue = new Double(df.format(calculatedValue));
					GroveLed ledPin = node.getLedNode();
					if (calculatedValue > 3.0) {
						ledPin.set(true);
					}else {
						ledPin.set(false);
					}
					break;
				case "Button": //$NON-NLS-1$
					boolean value = node.getButtonNode().get();
					fvalue = value ? 1.0 : 0.0;
					node.getBuzzerNode().set(value);
					break;
				default:
					break;
				}
			} catch (Exception e) {
				if (try_num < 3) {
					String msg = String.format("Exception when reading data from sensor node (will retry)\n%s", //$NON-NLS-1$
							e.toString());
					_logger.error(msg);
				} else {
					throw new RuntimeException("Exception when reading data from the sensor node", e); //$NON-NLS-1$
				}
			}
			break;
		}
    	
        PEnvelope envelope = new PEnvelope(fvalue);
        pDataValue = new PDataValue(node.getNodeId(), envelope);
        pDataValue.setNodeName(node.getName());
        pDataValue.setAddress(node.getAddress());
        // Do not return null.
        return pDataValue;
    }

    /*
     * Writes data value into data cache.
     */
    @Override
	public void writeData(UUID nodeId, PDataValue value)
            throws MachineAdapterException
    {
        if ( this.dataValueCache.containsKey(nodeId) )
        {
            // Put data into cache. The value typically should be written to a device node.
            this.dataValueCache.put(nodeId, value);
        }
    }

    /*
     * ###################################################
     * # ISubscriptionMachineAdapter interface methods #
     * ###################################################
     */

    /*
     * Returns list of all subscriptions.
     */
    @Override
	public List<IDataSubscription> getSubscriptions()
    {
        return new ArrayList<IDataSubscription>(this.dataSubscriptions.values());
    }

    /*
     * Adds new data subscription into the list.
     */
    @Override
	public synchronized UUID addDataSubscription(IDataSubscription subscription)
            throws MachineAdapterException
    {
        if ( subscription == null )
        {
            throw new IllegalArgumentException("Subscription is null"); //$NON-NLS-1$
        }

        List<PDataNode> subscriptionNodes = new ArrayList<PDataNode>();

        // Add new data subscription.
        if ( !this.dataSubscriptions.containsKey(subscription.getId()) )
        {
            // Make sure that new subscription contains valid nodes.
            for (PDataNode node : subscription.getSubscriptionNodes())
            {
                if ( !this.dataNodes.containsKey(node.getNodeId()) )
                {
                    throw new MachineAdapterException("Node doesn't exist for this adapter"); //$NON-NLS-1$
                }

                subscriptionNodes.add(this.dataNodes.get(node.getNodeId()));
            }

            // Create new subscription.
            WorkshopDataSubscription newSubscription = new WorkshopDataSubscription(this, subscription.getName(),
                    subscription.getUpdateInterval(), subscriptionNodes);
            this.dataSubscriptions.put(newSubscription.getId(), newSubscription);
            new Thread(newSubscription).start();
            return newSubscription.getId();
        }

        return null;
    }

    /*
     * Remove data subscription from the list
     */
    @Override
	public synchronized void removeDataSubscription(UUID subscriptionId)
    {
        // Stop subscription, notify all subscribers, and remove subscription
        if ( this.dataSubscriptions.containsKey(subscriptionId) )
        {
            this.dataSubscriptions.get(subscriptionId).stop();
            this.dataSubscriptions.remove(subscriptionId);
        }
    }

    /**
     * get subscription given subscription id.
     */
    @Override
	public IDataSubscription getDataSubscription(UUID subscriptionId)
    {
        if ( this.dataSubscriptions.containsKey(subscriptionId) )
        {
            return this.dataSubscriptions.get(subscriptionId);
        }
        throw new MachineAdapterException("Subscription does not exist"); //$NON-NLS-1$ 
    }

    @Override
	public synchronized void addDataSubscriptionListener(UUID dataSubscriptionId, IDataSubscriptionListener listener)
            throws MachineAdapterException
    {
        if ( this.dataSubscriptions.containsKey(dataSubscriptionId) )
        {
            this.dataSubscriptions.get(dataSubscriptionId).addDataSubscriptionListener(listener);
            return;
        }
        throw new MachineAdapterException("Subscription does not exist"); //$NON-NLS-1$	
    }

    @Override
	public synchronized void removeDataSubscriptionListener(UUID dataSubscriptionId, IDataSubscriptionListener listener)
    {
        if ( this.dataSubscriptions.containsKey(dataSubscriptionId) )
        {
            this.dataSubscriptions.get(dataSubscriptionId).removeDataSubscriptionListener(listener);
        }
    }

    /*
     * #####################################
     * # Private methods #
     * #####################################
     */

    /**
     * Generates random nodes
     * 
     * @param count of nodes
     */
    private void createNodes(List<JsonDataNode> nodes)
    {
        for (JsonDataNode jsonNode:nodes)
        {
                WorkshopDataNodePI node = new WorkshopDataNodePI(this.uuid, jsonNode.getNodeName(),jsonNode.getNodeType(),jsonNode.getNodePin());
	            // Create a new node and put it in the cache.
	            this.dataNodes.put(node.getNodeId(), node);
            
        }
    }

    // Put data into data cache.
    /**
     * @param values list of values
     */
    protected void putData(List<PDataValue> values)
    {
        for (PDataValue value : values)
        {
            this.dataValueCache.put(value.getNodeId(), value);
        }
    }


	@Override
	public void addSubscriptionAdapterListener(ISubscriptionAdapterListener arg0) {
		// TODO Auto-generated method stub
		
	}

	@Override
	public void removeSubscriptionAdapterListener(ISubscriptionAdapterListener arg0) {
		// TODO Auto-generated method stub
		
	}

	@Override
	public List<PDataNode> getEdgeDataNodes() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public UUID addEdgeDataSubscription(IEdgeDataSubscription arg0) throws MachineAdapterException {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public IEdgeDataSubscription getEdgeDataSubscription(UUID arg0) {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public List<IEdgeDataSubscription> getEdgeDataSubscriptions() {
		return new ArrayList<IEdgeDataSubscription>();
	}

	@Override
	public void removeEdgeDataSubscription(UUID arg0) {
		// TODO Auto-generated method stub
		
	}
}
