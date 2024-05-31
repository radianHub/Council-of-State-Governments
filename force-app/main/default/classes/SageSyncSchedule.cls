public with sharing class SageSyncSchedule implements Schedulable {
    public void execute(SchedulableContext sc) {
        SageIntegrationService.getInvoices();
        SageIntegrationService.getProjects();
    }
}