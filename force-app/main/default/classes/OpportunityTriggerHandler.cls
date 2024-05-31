public with sharing class OpportunityTriggerHandler extends TriggerHandler {
    List<Opportunity> newOpportunity;
    Map<Id, Opportunity> newOpportunityMap;
    List<Opportunity> oldOpportunity;
    Map<Id, Opportunity> oldOpportunityMap;

    public OpportunityTriggerHandler() {
        this.newOpportunity = (List<Opportunity>) Trigger.new;
        this.newOpportunityMap = (Map<Id, Opportunity>) Trigger.newMap;
        this.oldOpportunity = (List<Opportunity>) Trigger.old;
        this.oldOpportunityMap = (Map<Id, Opportunity>) Trigger.oldMap;
    }

    public override void beforeUpdate() {
        OpportunityService.syncProject(newOpportunity, oldOpportunityMap);
    }
}