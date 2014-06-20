trigger CreateAttendencesOnNewSession on Program_Session__c (after insert) 
{
    private Program_Session__c[] newSessions =Trigger.new;
    private Attendance__c[] attendances = new Attendance__c[0];
    For (Program_Session__c sNew: newSessions)
    {
    	Enrolment__c [] youngPeople = [select Young_Person__c from Enrolment__c where Program_Service__c = :sNew.Program_Service__c];
    	for (Enrolment__c onePersonEnrolment: youngPeople)
    	{
    		Attendance__c oneAttended = new Attendance__c (Young_Person__c=onePersonEnrolment.Young_Person__c, Program_Session__c=sNew.id, Enrolment__c=onePersonEnrolment.id);
    		attendances.add (oneAttended);
    	} 
    }
    insert attendances;
}