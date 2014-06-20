trigger UpdateTimeSinceLastHarmReduction on Harm_Reduction_NX__c (before insert) 
{
    Set<Id> setContacts = new Set<ID>();

 	for(Harm_Reduction_NX__c od : Trigger.new)
    {
        setContacts.add(od.Client__c);
    }
    
    Map<ID, Contact> mapClients = new Map<ID, Contact>([select Id, Date_of_last_Harm_Reduction_NX__c from Contact where ID in :setContacts]);
  	for(Harm_Reduction_NX__c od : Trigger.new)
    {
    	Contact client = mapClients.get(od.Client__c);
    	if (client != null && od.Date_of_intervention__c != null)
    	{
    		if (client.Date_of_last_Harm_Reduction_NX__c == null || client.Date_of_last_Harm_Reduction_NX__c < od.Date_of_intervention__c) 
    			client.Date_of_last_Harm_Reduction_NX__c = od.Date_of_intervention__c;
    	} 
    }
	update mapClients.values();
}