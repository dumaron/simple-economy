!doNothing.

+!doNothing.

+?introduction(Firm) <-
	+introduction(Firm).

+respawnFirm(FirmName) <-
	.print("respawn ", FirmName);
	.create_agent(FirmName, "firm.asl").

