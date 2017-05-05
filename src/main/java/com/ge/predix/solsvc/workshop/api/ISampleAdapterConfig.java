package com.ge.predix.solsvc.workshop.api;

import java.util.Map;
import java.util.UUID;

import com.ge.predix.solsvc.workshop.types.WorkshopDataNodePI;


public interface ISampleAdapterConfig {
	public static final String PROPKEY_UPDATE_INTERVAL = "com.ge.predix.solsvc.workshop.adapter.UpdateInterval";
	public static final String PROPKEY_NODES_CONFIG_FILE = "com.ge.predix.solsvc.workshop.adapter.NodeConfigFile";
	public static final String PROPKEY_DATA_SUBSCRIPTONS = "com.ge.predix.solsvc.workshop.adapter.DataSubscriptions";
	public static final String PROPKEY_ADAPTER_NAME = "com.ge.predix.solsvc.workshop.adapter.Name";
	public static final String PROPKEY_ADAPTER_DESCRIPTION = "com.ge.predix.solsvc.workshop.adapter.Description";
	
	int getUpdateInterval();
	String getNodeConfigFile();
	String getAdapterName();
	String getAdapterDescription();
	String[] getDataSubscriptions();
	public Map<UUID, WorkshopDataNodePI> getDataNodes();
}
