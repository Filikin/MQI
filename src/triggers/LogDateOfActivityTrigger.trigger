trigger LogDateOfActivityTrigger on Event (before insert, before update) 
{ 
	List<Event> TaskList = new List<Event>();
    Map<Id, Event> mapTasks = new Map<Id, Event>();
    Set<Id> whoIds = new Set<Id>();

    for(Event t : Trigger.new)
    {
        if (t.WhoId != null)
        {
 	        //Add the Event to the Map and Set
            mapTasks.put(t.WhoId, t);
            whoIds.add(t.WhoId);
        }
    }
    
    List<Contact> clients = [select Id, Date_of_last_support_event__c, Member_of_Travelling_Community__c, Region__c, Family_Support_Client__c, Aftercare_client__c from Contact where ID in :whoIDs];
    for (Contact client: clients)
    {
    	Event tsk = mapTasks.get(client.Id);
    	if (tsk.Event_status__c == 'Done')
        {
	    	if (Trigger.isInsert && client.Date_of_last_support_event__c != null) tsk.Days_since_last_activity__c = client.Date_of_last_support_event__c.daysBetween(tsk.StartDateTime.Date()); 
    		client.Date_of_last_support_event__c = tsk.StartDateTime.Date();
    		if (client.Status__c == 'Inactive') client.Status__c = 'Active';
        }
    	tsk.Member_of_Travelling_Community__c = client.Member_of_Travelling_Community__c;
    	tsk.Family_support_client__c = client.Family_support_client__c;
    	tsk.Aftercare_client__c = client.Aftercare_client__c;
    	tsk.Region__c = client.Region__c;
    }
    update clients;
}