public with sharing class PaymentProcessorController {

    @AuraEnabled(cacheable=true)
    public static Payment_Processor__c getSettings() {
        return Payment_Processor__c.getOrgDefaults();
    }

    // * SUCCESSFUL DONATION
    @AuraEnabled
    public static void successfulPayment(String processor, String jsonData, Boolean isDonation) {
        try {
            if (isDonation) {
                donationPayment(processor, jsonData);
            } else {
                invoicePayment(processor, jsonData);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    static void donationPayment(String processor, String jsonData) {
        try {
            if (processor == 'Auth.net') {
                AuthNetResponse data = AuthNetResponse.parseJSON(jsonData);
                Map<String, Object> respMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(data));
                for(String key : respMap.keySet()) {
                    System.debug(key);
                    System.debug(respMap.get(key));
                }

    
                Contact payee = new Contact(
                    FirstName = data.detail.firstName,
                    LastName = data.detail.lastName,
                    Email = data.detail.email,
                    Phone = data.detail.phone,
                    MailingStreet = data.detail.street,
                    MailingCity = data.detail.city,
                    MailingState = data.detail.state,
                    MailingPostalCode = data.detail.zip,
                    Id = data.detail.contactId
                );
                upsert payee;
    
                Contact honoree;
                if (data.detail.isHonoree) {
                    honoree = new Contact(
                        FirstName = data.detail.honoree.FirstName,
                        LastName = data.detail.honoree.LastName,
                        Phone = data.detail.honoree.Phone,
                        Email = data.detail.honoree.Email,
                        MailingStreet = data.detail.honoree.Street,
                        MailingCity = data.detail.honoree.City,
                        MailingState = data.detail.honoree.State,
                        MailingPostalCode = data.detail.honoree.Zip
                    );
                    insert honoree;
                }
    
                // TODO: WHAT SAGE FIELDS NEED TO BE SET?
                // TODO: RECORD TYPE?
                Opportunity donation = new Opportunity(
                    Name = String.format(
                        '{0} ({1} {2}) Donation - {3}', 
                        new String[]{
                            data.detail.company, 
                            data.detail.firstName, 
                            data.detail.lastName, 
                            data.detail.recurringInterval.startDate.format()
                        }
                    ),
                    AccountId = [SELECT AccountId FROM Contact WHERE Id = :payee.Id].AccountId,
                    CloseDate = data.detail.recurringInterval.startDate,
                    StageName = 'Closed Won',
                    Amount = data.detail.amount
                );
                insert donation;
    
                OpportunityContactRole payeeRole = new OpportunityContactRole(
                    ContactId = payee.Id,
                    OpportunityId = donation.Id,
                    IsPrimary = true
                );
                
                OpportunityContactRole honoreeRole;
                if (data.detail.isHonoree) {
                    honoreeRole = new OpportunityContactRole(
                        ContactId = honoree.Id,
                        OpportunityId = donation.Id
                    );  
                }            
                insert new OpportunityContactRole[]{payeeRole, honoreeRole};
    
                // TODO: CREATE INVOICE
                // TODO: CREATE PAYMENT
                // TODO: SEND TO SAGE
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    static void invoicePayment(String processor, String jsonData) {
        try {
            if (processor == 'Auth.net') {
                AuthNetResponse data = AuthNetResponse.parseJSON(jsonData);
                Map<String, Object> respMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(data));
                for(String key : respMap.keySet()) {
                    System.debug(key);
                    System.debug(respMap.get(key));
                } 
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}