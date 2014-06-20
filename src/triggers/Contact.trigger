/*

Author: Eamon Kelly, Enclude

Purpose: Copy fields required for HRB report

Called from: pdate or insert contact

*/
trigger Contact on Contact (before insert, before update) 
{
	for (Contact oneClient: trigger.new)
	{
		oneClient.ecass01__X4_Gender__c = oneClient.Gender__c;
	}
}