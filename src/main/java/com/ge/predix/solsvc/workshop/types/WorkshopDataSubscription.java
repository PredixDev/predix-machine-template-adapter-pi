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

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicBoolean;

import com.ge.dspmicro.hoover.api.spillway.ISpillway;
import com.ge.dspmicro.machinegateway.api.adapter.IDataSubscription;
import com.ge.dspmicro.machinegateway.api.adapter.IDataSubscriptionListener;
import com.ge.dspmicro.machinegateway.api.adapter.ISubscriptionMachineAdapter;
import com.ge.dspmicro.machinegateway.types.ITransferable;
import com.ge.dspmicro.machinegateway.types.PDataNode;

/**
 * 
 * @author Predix Machine Sample
 */
@SuppressWarnings("deprecation")
public class WorkshopDataSubscription implements Runnable, IDataSubscription {
	private UUID uuid;
	private String name;
	private int updateInterval;
	private ISubscriptionMachineAdapter adapter;
	private List<IDataSubscriptionListener> listeners = new ArrayList<IDataSubscriptionListener>();
	private final AtomicBoolean threadRunning = new AtomicBoolean();

	private ISpillway spillway;
	
	/**
	 * Constructor
	 * 
	 * @param adapter
	 *            machine adapter
	 * @param subName
	 *            Name of this subscription
	 * @param updateInterval
	 *            in milliseconds
	 * @param nodes
	 *            list of nodes for this subscription
	 */
	public WorkshopDataSubscription(ISubscriptionMachineAdapter adapter, String subName, int updateInterval,
			List<PDataNode> nodes,ISpillway spillway) {
		if (updateInterval > 0) {
			this.updateInterval = updateInterval;
		} else {
			throw new IllegalArgumentException("updataInterval must be greater than zero."); //$NON-NLS-1$
		}

		
		this.adapter = adapter;
		this.spillway = spillway;
		
		// Generate unique id.
		this.uuid = UUID.randomUUID();
		this.name = subName;
		this.threadRunning.set(false);
	}

	@Override
	public UUID getId() {
		return this.uuid;
	}

	@Override
	public String getName() {
		return this.name;
	}

	@Override
	public int getUpdateInterval() {
		return this.updateInterval;
	}

	@Override
	public List<PDataNode> getSubscriptionNodes() {
		return this.adapter.getNodes();
	}

	/**
	 * @param listener
	 *            callback listener
	 */
	@Override
	public synchronized void addDataSubscriptionListener(IDataSubscriptionListener listener) {
		if (!this.listeners.contains(listener)) {
			this.listeners.add(listener);
		}
	}

	/**
	 * @param listener
	 *            callback listener
	 */
	@Override
	public synchronized void removeDataSubscriptionListener(IDataSubscriptionListener listener) {
		if (!this.listeners.contains(listener)) {
			this.listeners.remove(listener);
		}
	}

	/**
	 * get all listeners
	 * 
	 * @return a list of listeners.
	 */
	@Override
	public synchronized List<IDataSubscriptionListener> getDataSubscriptionListeners() {
		return this.listeners;
	}

	/**
	 * Thread to generate random data for the nodes in this subscription.
	 */
	@Override
	public void run() {
		if (!this.threadRunning.get() && this.adapter.getNodes().size() > 0) {
			this.threadRunning.set(true);
			while (this.threadRunning.get()) {
				// Generate random data for each node and push data update.
				List<ITransferable> dataList = new ArrayList<ITransferable>();
				
				for (PDataNode node : this.adapter.getNodes()) {
					WorkshopDataNodePI wNode = (WorkshopDataNodePI)node;
					if ("IN".equals(wNode.getNodePinDir())) { //$NON-NLS-1$
						dataList.add(this.adapter.readData(node.getNodeId()));
					}
				}

				spillway.processAndTransferData(dataList);
				
				try {
					// Wait for an updateInterval period before pushing next
					// data update.
					Thread.sleep(this.updateInterval);
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
			}
		}
	}

	/**
	 * Stops generating random data.
	 */
	public void stop() {
		if (this.threadRunning.get()) {
			this.threadRunning.set(false);

			// Send notification to all listeners.
			for (IDataSubscriptionListener listener : this.listeners) {
				listener.onSubscriptionDelete(this.adapter, this.uuid);
			}

			// Do other clean up if needed...
		}
	}

	public ISpillway getSpillway() {
		return spillway;
	}

	public void setSpillway(ISpillway spillway) {
		this.spillway = spillway;
	}
}
