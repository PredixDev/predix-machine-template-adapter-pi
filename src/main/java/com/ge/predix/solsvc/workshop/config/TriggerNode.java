package com.ge.predix.solsvc.workshop.config;

/**
 * 
 * @author 212546387 -
 */
public class TriggerNode {

		private String nodeName;
		private String nodeValueExpression;
		
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
		public String getNodeValueExpression() {
			return this.nodeValueExpression;
		}
		/**
		 * @param nodeValueExpression -
		 */
		public void setNodeValueExpression(String nodeValueExpression) {
			this.nodeValueExpression = nodeValueExpression;
		}
		
}
