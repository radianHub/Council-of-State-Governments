public with sharing class PaymentProcessorController {
    
    @AuraEnabled(cacheable=true)
    public static Authorize_net__c getSettings() {
        return Authorize_net__c.getOrgDefaults();
    }
}