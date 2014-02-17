!doNothing.

+!doNothing.

+?introduction(Firm) <-
	+introduction(Firm).

+respawnFirm(FirmName) <-
	.print("respawn ", FirmName);
	-respawnFirm(FirmName);
	.create_agent(FirmName, "firm.asl").
	//created(FirmName).
