Feature: Bid on a megatile
	Players should be able to bid on megatiles
	
	Scenario: Bid on unowned megatile
		Given I have a world
		Given I have one user "riley@example.com" with password "letmein"
		Given I have a player in the world
		Given I have an unowned megatile in the world
		When I bid 42 on the unowned megatile
		Then I should get a bid id
		
	Scenario: Bid a negative price on unowned megatile
		Given I have a world
		Given I have one user "riley@example.com" with password "letmein"
		Given I have a player in the world
		Given I have an unowned megatile in the world
		When I bid -42 on the unowned megatile
		Then I should not get a bid id

	Scenario: Bid on an owned megatile
		Given I have a world
		Given I have one user "riley@example.com" with password "letmein"
		Given I have a player in the world
		Given I have an owned megatile in the world
		When I bid 42 on the owned megatile
		Then I should get a bid id
		And The megatile's owner should get an email notification of the bid
	