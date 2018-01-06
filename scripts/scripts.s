stubScript:
	scriptend

genericNpcScript:
	initcollisions
--
	checkabutton
	showloadedtext
	jump2byte --



faroreScript:
	jumptable_memoryaddress wIsLinkedGame
	.dw _faroreUnlinked
	.dw _faroreLinked

; When talking to farore in a completed unlinked game, you can tell her secrets, but all
; she'll do is direct you to the person you're supposed to tell them to.
_faroreUnlinked:
	jumpifglobalflagset GLOBALFLAG_FINISHEDGAME @finishedGame
	rungenericnpclowindex <TX_5501

@finishedGame:
	initcollisions
@npcLoop:
	enableinput
	checkabutton
	setdisabledobjectsto91
	showtextlowindex <TX_5502
	jumpiftextoptioneq $00 @askForPassword

@offerHolodrumSecret:
	showtextlowindex <TX_5519
	jumpiftextoptioneq $00 @sayHolodrumSecret
	showtextlowindex <TX_5505
	jump2byte @npcLoop

@sayHolodrumSecret:
	asm15 scriptHlp.faroreGenerateGameTransferSecret
	showtextlowindex <TX_551a
	jump2byte @npcLoop

@askForPassword:
	askforsecret $ff
	asm15 scriptHlp.faroreCheckSecretValidity
	jumptable_interactionbyte Interaction.var3f
	.dw @offerHolodrumSecret
	.dw @offerHolodrumSecret
	.dw @offerHolodrumSecret
	.dw @secretOK
	.dw @wrongGame
	.dw @offerHolodrumSecret

@wrongGame: ; A Seasons secret was given in Ages.
	showtextlowindex <TX_550b
	jump2byte @offerHolodrumSecret

@secretOK: ; The secret is fine, but you're supposed to tell it to someone else.
	asm15 scriptHlp.faroreShowTextForSecretHint
	wait 30
	showtextlowindex <TX_5504
	jump2byte @offerHolodrumSecret


; When talking to Farore in a linked game, you can tell her secrets and she'll respond by
; giving you an item if it's correct.
_faroreLinked:
	initcollisions
	checkabutton
	setdisabledobjectsto91
	showtextlowindex <TX_5506
	jump2byte ++
@npcLoop:
	enableinput
	checkabutton
	disableinput
	jumpifglobalflagset GLOBALFLAG_SECRET_CHEST_WAITING @waitForLinkToOpenChest
++
	showtextlowindex <TX_5507 ; Do you know a secret?
	jumpiftextoptioneq $00 @showPasswordScreen
	showtextlowindex <TX_5508 ; Come back anytime
	jump2byte @npcLoop

@showPasswordScreen:
	askforsecret $ff
	asm15 scriptHlp.faroreCheckSecretValidity
	jumptable_interactionbyte $7f
	.dw @script4667
	.dw @secretOK
	.dw @alreadyToldSecret
	.dw @script4667
	.dw @wrongGame
	.dw @secretNotActive

@script4667:
	showtextlowindex <TX_5505
	jump2byte @npcLoop

@secretOK:
	asm15 scriptHlp.faroreSpawnSecretChest
	checkcfc0bit 1
	xorcfc0bit 1
	enableinput
	jump2byte @npcLoop

@alreadyToldSecret: ; The secret has already been told to farore
	showtextlowindex <TX_550c
	jump2byte @npcLoop

@wrongGame: ; A secret for Seasons was told in Ages
	showtextlowindex <TX_550b
	jump2byte @npcLoop

@secretNotActive: ; Need to talk to the corresponding npc before you can tell the secret
	showtextlowindex <TX_551c
	jump2byte @npcLoop

@waitForLinkToOpenChest: ; A chest exists already, waiting for Link to open it
	showtextlowindex <TX_550a
	jump2byte @npcLoop


script4683:
	checkitemflag
	checknoenemies
	spawnitem $3001
	scriptend
script4689:
	checkitemflag
	setcollisionradii $04 $06
	checknoenemies
	playsound $4d
	createpuff
	wait 30
	settilehere $f1
	setstate $ff
	scriptend
script4697:
	checkroomflag80
	checknoenemies
	orroomflag $80
	scriptend


faroresMemoryScript:
	initcollisions
--
	enableinput
	checkabutton
	setdisabledobjectsto91
	showtext TX_551b
	jumpiftextoptioneq $00 @openSecretList
	wait 8
	jump2byte --

@openSecretList:
	asm15 openMenu $0a
	wait 8
	jump2byte --


; ==================================================
; Door opener/closer scripts
; ==================================================
;
; Used with INTERACID_DOOR_CONTROLLER.
;
; States:
;   $01: does nothing except run the script
;   $02: opens the door
;   $03: closes the door
;
; Variables:
;   angle: the type and direction of door (see interactionTypes.s)
;   speed: for subids $14-$17, this is the number of torches that must be lit.
;   var3d: Bitmask to check on wActiveTriggers (value of "X" parameter converted to
;          a bitmask)
;   var3e: Short-form position of the tile the door is on (value of "Y" parameter)
;   var3f: Value of "X" parameter (a number from 0-7 corrresponding to a switch; see
;          var3e)


_doorController_updateRespawnWhenLinkNotTouching:
	checknotcollidedwithlink_ignorez
	asm15 scriptHlp.doorController_updateLinkRespawn
	retscript


; Subid $00: door just opens.
doorOpenerScript:
	setstate $ff
	scriptend


; Subids $04-$07:
;   Door is controlled by a bit in "wActiveTriggers" (uses the bitmask in var3d).

; Subid $04
doorController_controlledByTriggers_up:
	setcollisionradii $0a $08
	setangle $10
	jump2byte _doorController_controlledByTriggers

; Subid $05
doorController_controlledByTriggers_right:
	setcollisionradii $08 $0a
	setangle $12
	jump2byte _doorController_controlledByTriggers

; Subid $06
doorController_controlledByTriggers_down:
	setcollisionradii $0a $08
	setangle $14
	jump2byte _doorController_controlledByTriggers

; Subid $07
doorController_controlledByTriggers_left:
	setcollisionradii $08 $0a
	setangle $16

_doorController_controlledByTriggers:
	callscript _doorController_updateRespawnWhenLinkNotTouching
@loop:
	asm15 scriptHlp.doorController_decideActionBasedOnTriggers
	jumptable_memoryaddress $cfc1
	.dw @loop
	.dw @open
	.dw @close
@open:
	playsound SND_SOLVEPUZZLE
	setstate $02
	jump2byte @loop
@close:
	setstate $03
	jump2byte @loop


; Subids $08-$0b:
;   Door shuts itself until [wNumEnemies] == 0.

_doorController_shutUntilEnemiesDead:
	callscript _doorController_updateRespawnWhenLinkNotTouching
	jumpifnoenemies @end
	setstate $03
	checknoenemies
	playsound SND_SOLVEPUZZLE
	wait 8
	setstate $ff
@end:
	scriptend

_doorController_open:
	setstate $02
	scriptend

; Subid $08
doorController_shutUntilEnemiesDead_up:
	setcollisionradii $0a $08
	setangle $10
	jumpifnoenemies _doorController_open
	jump2byte _doorController_shutUntilEnemiesDead

; Subid $09
doorController_shutUntilEnemiesDead_right:
	setcollisionradii $08 $0a
	setangle $12
	jumpifnoenemies _doorController_open
	jump2byte _doorController_shutUntilEnemiesDead

; Subid $0a
doorController_shutUntilEnemiesDead_down:
	setcollisionradii $0a $08
	setangle $14
	jumpifnoenemies _doorController_open
	jump2byte _doorController_shutUntilEnemiesDead

; Subid $0b
doorController_shutUntilEnemiesDead_left:
	setcollisionradii $08 $0a
	setangle $16
	jumpifnoenemies _doorController_open
	jump2byte _doorController_shutUntilEnemiesDead

_doorController_openOnMinecartCollision:
	asm15 scriptHlp.doorController_checkMinecartCollidedWithDoor
	jumptable_memoryaddress $cfc1
	.dw _doorController_openOnMinecartCollision
	.dw @incState

@incState:
	setstate $ff

_doorController_closeDoorWhenLinkNotTouching:
	callscript _doorController_updateRespawnWhenLinkNotTouching
	setstate $03
	scriptend

script4738:
	asm15 scriptHlp.doorController_checkTileIsMinecartTrack
	jumptable_memoryaddress $cfc1
	.dw _doorController_openOnMinecartCollision ; Not minecart track (door is closed)
	.dw _doorController_closeDoorWhenLinkNotTouching ; Minecart track (door is open)


; Subids $08-$0f:
;   Minecart door; opens when a minecart collides with it

; Subid $0c
doorController_minecartDoor_up:
	setcollisionradii $10 $08
	setangle $18
	jump2byte script4738

; Subid $0d
doorController_minecartDoor_right:
	setcollisionradii $08 $0e
	setangle $1a
	jump2byte script4738

; Subid $0e
doorController_minecartDoor_down:
	setcollisionradii $0f $08
	setangle $1c
	jump2byte script4738

; Subid $0f
doorController_minecartDoor_left:
	setcollisionradii $08 $0f
	setangle $1e
	jump2byte script4738


; Subids $10-$13:
;   Door which automatically closes when Link walks out of that tile.
;   When Link transitions onto a shutter door tile, the game automatically removes that
;   tile and replaces it with an interaction of this type.

_doorController_closeDoorWhenLinkNotTouchingAndFlipcfc0:
	callscript _doorController_updateRespawnWhenLinkNotTouching
	setstate $03
	xorcfc0bit 0
	scriptend

; Subid $10
doorController_closeAfterLinkEnters_up:
	setcollisionradii $0c $08
	setangle $10
	jump2byte _doorController_closeDoorWhenLinkNotTouchingAndFlipcfc0

; Subid $11
doorController_closeAfterLinkEnters_right:
	setcollisionradii $08 $0c
	setangle $12
	jump2byte _doorController_closeDoorWhenLinkNotTouchingAndFlipcfc0

; Subid $12
doorController_closeAfterLinkEnters_down:
	setcollisionradii $0c $08
	setangle $14
	jump2byte _doorController_closeDoorWhenLinkNotTouchingAndFlipcfc0

; Subid $13
doorController_closeAfterLinkEnters_left:
	setcollisionradii $08 $0c
	setangle $16
	jump2byte _doorController_closeDoorWhenLinkNotTouchingAndFlipcfc0


; Subids $14-$17:
;   Door opens when a number of torches are lit.

_doorController_shutUntilTorchesLit:
	callscript _doorController_updateRespawnWhenLinkNotTouching
	setstate $03
@loop:
	asm15 scriptHlp.doorController_checkEnoughTorchesLit
	jumptable_memoryaddress $cec0
	.dw @loop
	.dw @torchesLit

@torchesLit:
	wait 30
	playsound SND_SOLVEPUZZLE
	setstate $ff
	scriptend

; Subid $14
doorController_openWhenTorchesLit_up_2Torches:
	setcollisionradii $0a $08
	setangle $10
	setspeed $02
	jump2byte _doorController_shutUntilTorchesLit

; Subid $15
doorController_openWhenTorchesLit_left_2Torches:
	setcollisionradii $08 $0a
	setangle $16
	setspeed $02
	jump2byte _doorController_shutUntilTorchesLit

; Subid $16
doorController_openWhenTorchesLit_down_1Torch:
	setcollisionradii $0a $08
	setangle $14
	setspeed $01
	jump2byte _doorController_shutUntilTorchesLit

; Subid $17
doorController_openWhenTorchesLit_left_1Torch:
	setcollisionradii $08 $0a
	setangle $16
	setspeed $01
	jump2byte _doorController_shutUntilTorchesLit





script47ba:
	showtext $0000
script47bd:
	showtext $2000
script47c0:
	showtext $2600
	jumptable_interactionbyte $77
	.dw script47f1
	.dw script4805
	.dw script4817
	.dw script480b
	.dw script4811
	.dw script4821
	.dw script482b
	.dw script47f1
	.dw script47f1
	.dw script47f1
	.dw script47f1
	.dw script47f1
	.dw script47f1
	.dw script4835
	.dw script483b
	.dw script4845
	.dw script484f
	.dw script4859
	.dw script485f
	.dw script4865
	.dw script47f1
	.dw script486f
script47f1:
	jumpifitemobtained $2c script47fb
	showtextlowindex $0b
	writeinteractionbyte $7a $ff
	scriptend
script47fb:
	showtextnonexitablelowindex $09
	callscript script4879
	ormemory $c642 $01
	scriptend
script4805:
	showtextnonexitablelowindex $02
	callscript script4879
	scriptend
script480b:
	showtextnonexitablelowindex $03
	callscript script4879
	scriptend
script4811:
	showtextnonexitablelowindex $04
	callscript script4879
	scriptend
script4817:
	showtextnonexitablelowindex $1d
	callscript script4879
	ormemory $c642 $02
	scriptend
script4821:
	showtextnonexitablelowindex $25
	callscript script4879
	ormemory $c642 $08
	scriptend
script482b:
	showtextnonexitablelowindex $1d
	callscript script4879
	ormemory $c642 $04
	scriptend
script4835:
	showtextnonexitablelowindex $1b
	callscript script4879
	scriptend
script483b:
	showtextnonexitablelowindex $1d
	callscript script4879
	ormemory $c643 $01
	scriptend
script4845:
	showtextnonexitablelowindex $23
	callscript script4879
	ormemory $c643 $02
	scriptend
script484f:
	showtextnonexitablelowindex $25
	callscript script4879
	ormemory $c643 $04
	scriptend
script4859:
	showtextnonexitablelowindex $29
	callscript script4879
	scriptend
script485f:
	showtextnonexitablelowindex $2a
	callscript script4879
	scriptend
script4865:
	showtextnonexitablelowindex $1d
	callscript script4879
	ormemory $c642 $20
	scriptend
script486f:
	showtextnonexitablelowindex $01
	callscript script4879
	ormemory $c643 $40
	scriptend
script4879:
	jumpiftextoptioneq $00 script4889
	writememory $cbad $03
	writememory $cba0 $01
	writeinteractionbyte $7a $ff
	scriptend
script4889:
	jumpifmemoryeq $ccd5 $00 script489d
	showtextlowindex $06
script4891:
	writeinteractionbyte $7a $ff
	setdisabledobjectsto00
	scriptend
script4896:
	callscript script49a5
script4899:
	showtextlowindex $06
	jump2byte script4891
script489d:
	jumptable_interactionbyte $78
	.dw script48a3
	.dw script48ac
script48a3:
	writememory $cba0 $01
	writeinteractionbyte $7a $01
	disablemenu
	retscript
script48ac:
	writememory $cbad $02
	writememory $cba0 $01
	writeinteractionbyte $7a $ff
	scriptend
script48b8:
	setspeed SPEED_200
	playsound $50
	movenpcdown $10
	movenpcright $18
	showtextlowindex $07
	movenpcleft $18
	movenpcup $10
	setangleandanimation $08
	setdisabledobjectsto00
	scriptend
script48ca:
	setspeed SPEED_200
	movenpcup $10
	showtextlowindex $07
	setdisabledobjectsto11
	movenpcdown $10
	setangleandanimation $08
	setdisabledobjectsto00
	scriptend
script48d7:
	setspeed SPEED_200
	playsound $50
	movenpcdown $08
	movenpcleft $18
	showtextlowindex $07
	movenpcright $18
	movenpcup $08
	setangleandanimation $18
	setdisabledobjectsto00
	scriptend
script48e9:
	jumpifc6xxset $42 $80 script48f6
	showtextlowindex $0d
	ormemory $c642 $80
	jump2byte script48f8
script48f6:
	showtextlowindex $0e
script48f8:
	setdisabledobjectsto11
	jumpiftextoptioneq $00 script4901
	showtextlowindex $11
	setdisabledobjectsto00
	scriptend
script4901:
	jumpifmemoryeq $ccd5 $01 script4899
	asm15 $411c
	setspeed SPEED_200
	setcollisionradii $06 $06
	movenpcup $08
	movenpcright $19
	movenpcup $1a
	movenpcright $11
	movenpcdown $08
	jump2byte script491e
script491b:
	asm15 $411c
script491e:
	setangleandanimation $08
	writeinteractionbyte $45 $02
	writeinteractionbyte $44 $05
	wait 60
	setangleandanimation $18
	wait 60
	setangleandanimation $10
	writeinteractionbyte $7c $00
	showtextlowindex $10
	setdisabledobjectsto00
	ormemory $ccd3 $80
	writeinteractionbyte $45 $00
	writeinteractionbyte $44 $05
	setdisabledobjectsto11
	showtextlowindex $17
	jumpiftextoptioneq $01 script494b
	jumpifmemoryeq $ccd5 $01 script4896
	jump2byte script491b
script494b:
	callscript script49a5
	setdisabledobjectsto00
	scriptend
script4950:
	setdisabledobjectsto11
	jumptable_interactionbyte $7c
	.dw script495f
	.dw script495f
	.dw script495f
	.dw script4973
	.dw script4983
	.dw script4993
script495f:
	showtextlowindex $13
	setangleandanimation $08
	writeinteractionbyte $45 $02
	writeinteractionbyte $44 $05
	wait 60
	setangleandanimation $18
	wait 60
	setangleandanimation $10
	showtextlowindex $18
	setdisabledobjectsto00
	scriptend
script4973:
	showtextlowindex $12
	jumpiftextoptioneq $00 script495f
	showtextlowindex $14
	writeinteractionbyte $7f $03
	callscript script49a5
	setdisabledobjectsto00
	scriptend
script4983:
	showtextlowindex $15
	jumpiftextoptioneq $00 script495f
	showtextlowindex $14
	writeinteractionbyte $7f $02
	callscript script49a5
	setdisabledobjectsto00
	scriptend
script4993:
	showtextlowindex $16
	writeinteractionbyte $7f $01
	callscript script49a5
	setdisabledobjectsto00
	scriptend
script499d:
	showtextlowindex $1a
	writeinteractionbyte $45 $01
	writeinteractionbyte $44 $05
script49a5:
	movenpcup $08
	movenpcleft $11
	movenpcdown $1a
	movenpcleft $19
	movenpcdown $08
	setangleandanimation $08
	setcollisionradii $06 $14
	retscript
script49b5:
	showtextlowindex $28
	scriptend
script49b8:
	setcollisionradii $09 $09
script49bb:
	wait 30
script49bc:
	checkcollidedwithlink_onground
	ormemory $cc95 $80
	asm15 dropLinkHeldItem
	setanimation $ff
	setstate $ff
script49c8:
	playsound $06
	asm15 $4248
	wait 180
	wait 180
	playsound $b4
	wait 20
	playsound $b4
	wait 20
	playsound $b4
	wait 40
	playsound $b4
	asm15 $4250
	scriptend
script49de:
	setcollisionradii $12 $06
	makeabuttonsensitive
script49e2:
	enableinput
	checkabutton
	disableinput
	jumpifglobalflagset $08 script4a40
	jumpifmemoryeq $cc01 $00 script4a08
	jumpifmemoryset $c615 $01 script49f7
	jump2byte script4a08
script49f7:
	showtextlowindex $3e
	jumpifinteractionbyteeq $76 $01 script4a04
	showtextlowindex $3b
	asm15 $4256
	wait 1
script4a04:
	setdisabledobjectsto11
	checktext
	jump2byte script4a37
script4a08:
	showtextnonexitablelowindex $00
script4a0a:
	jumpiftextoptioneq $00 script4a12
	showtextnonexitablelowindex $3a
	jump2byte script4a0a
script4a12:
	jumpifinteractionbyteeq $76 $01 script4a1f
	showtextlowindex $3b
	asm15 $4256
	wait 1
	setdisabledobjectsto11
	checktext
script4a1f:
	showtextlowindex $3f
	asm15 $42ed
	wait 1
	setdisabledobjectsto11
	checktext
	showtextlowindex $33
	asm15 $426e $00
	wait 10
	showtextlowindex $13
	asm15 $426e $01
	wait 10
	showtextlowindex $08
script4a37:
	setglobalflag $08
	ormemory $c615 $01
	enableinput
	jump2byte script49e2
script4a40:
	asm15 $42b2
	jumptable_interactionbyte $7b
	.dw script4a4d
	.dw script4a51
	.dw script4a55
	.dw script4a5d
script4a4d:
	showtextlowindex $36
	jump2byte script4a57
script4a51:
	showtextlowindex $37
	jump2byte script4a57
script4a55:
	showtextlowindex $39
script4a57:
	checktext
	asm15 $42f5
	jump2byte script49e2
script4a5d:
	showtextnonexitablelowindex $03
	jumpiftextoptioneq $00 script4a6c
	jumpiftextoptioneq $01 script4a77
	enableinput
	showtextlowindex $08
	jump2byte script49e2
script4a6c:
	jumpifinteractionbyteeq $77 $00 script4a94
	asm15 $426e $00
	jump2byte script4a80
script4a77:
	jumpifinteractionbyteeq $78 $00 script4a98
	asm15 $426e $01
script4a80:
	wait 10
	jumpifglobalflagset $09 script4a8a
	showtextlowindex $08
	enableinput
	jump2byte script49e2
script4a8a:
	showtextlowindex $38
	checktext
	setglobalflag $89
	asm15 $42f1
	jump2byte script49e2
script4a94:
	showtextlowindex $14
	jump2byte script49e2
script4a98:
	showtextlowindex $15
	jump2byte script49e2
script4a9c:
	showtextnonexitablelowindex $09
	jumpiftextoptioneq $00 script4aa8
	writememory $cba0 $01
	enableinput
	scriptend
script4aa8:
	wait 30
	showtextnonexitablelowindex $0a
	jumpiftextoptioneq $01 script4ab3
	showtextnonexitablelowindex $0b
	jump2byte script4ab5
script4ab3:
	showtextnonexitablelowindex $0c
script4ab5:
	jumpiftextoptioneq $00 script4aa8
	writememory $cba0 $01
	scriptend
script4abe:
	showtextnonexitablelowindex $1f
	jumpiftextoptioneq $01 script4ad2
	jump2byte script4acc
script4ac6:
	showtextnonexitablelowindex $24
	jumpiftextoptioneq $02 script4ad2
script4acc:
	setdisabledobjectsto11
	asm15 $428b
	wait 1
	scriptend
script4ad2:
	showtextlowindex $2e
	scriptend
script4ad5:
	showtextlowindex $0f
	scriptend
script4ad8:
	showtextlowindex $31
	scriptend
script4adb:
	showtextlowindex $2a
	scriptend
script4ade:
	showtextnonexitablelowindex $18
	jumpiftextoptioneq $02 script4b00
	jumpiftextoptioneq $00 script4af3
	asm15 $4280
script4aeb:
	showtextnonexitablelowindex $1d
	jumpiftextoptioneq $00 script4aeb
	jump2byte script4b00
script4af3:
	asm15 $427b
	wait 1
	jumpifmemoryeq $cc89 $00 script4b03
	showtextlowindex $1e
	scriptend
script4b00:
	showtextlowindex $10
	scriptend
script4b03:
	showtextlowindex $27
	scriptend
script4b06:
	setdisabledobjectsto11
	showtextlowindex $23
	asm15 $42f5
	wait 1
	checktext
	setdisabledobjectsto00
	scriptend
script4b10:
	showtextlowindex $27
	scriptend
script4b13:
	wait 30
	showtext $550d
	jumpiftextoptioneq $00 script4b24
	asm15 $42fe
	asm15 saveFile
	wait 30
	jump2byte script4b2c
script4b24:
	wait 30
	showtext $550e
	jumpiftextoptioneq $00 script4b13
script4b2c:
	writememory $cfde $01
	scriptend
script4b31:
	writememory $cba0 $01
script4b35:
	checkabutton
	showtextnonexitablelowindex $19
	jumpiftextoptioneq $01 script4b31
	showtextlowindex $1a
	jump2byte script4b35
script4b40:
	writememory $cba0 $01
script4b44:
	checkabutton
	showtextnonexitablelowindex $20
	jumpiftextoptioneq $01 script4b40
script4b4b:
	showtextnonexitablelowindex $25
	jumpiftextoptioneq $01 script4b5d
	jumpiftextoptioneq $02 script4b40
	showtextnonexitablelowindex $3d
	jumpiftextoptioneq $01 script4b40
	jump2byte script4b4b
script4b5d:
	showtextnonexitablelowindex $26
	jumpiftextoptioneq $01 script4b40
	jump2byte script4b4b


.include "scripts/dungeonScripts.s"


; ==============================================================================
; INTERACID_BIPIN
; ==============================================================================

; Running around when baby just born
bipinScript0:
	setcollisionradii $06 $06
	makeabuttonsensitive
@loop:
	checkabutton
	jumpifmemoryeq wChildStatus $00 @stillUnnamed
	showtext TX_4301
	jump2byte @loop
@stillUnnamed:
	showtext TX_4300
	jump2byte @loop


; Bipin gives you a random tip
bipinScript1:
	initcollisions
@loop:
	checkabutton
	setdisabledobjectsto91
	setanimation $02
	asm15 scriptHlp.bipin_showText_subid1To9
	wait 30
	callscript _bipinSayRandomTip
	setdisabledobjectsto00
	jump2byte @loop


; Bipin just moved to Labrynna/Holodrum?
bipinScript2:
	initcollisions
@loop:
	checkabutton
	setdisabledobjectsto91
	asm15 scriptHlp.bipin_showText_subid1To9
	setdisabledobjectsto00
	jump2byte @loop

_bipinSayRandomTip:
	; Show a random text index from TX_4309-TX_4310
	writeinteractionbyte Interaction.textID+1 >TX_4300
	getrandombits        Interaction.textID   $07
	addinteractionbyte   Interaction.textID   <TX_4309
	showloadedtext

	setanimation $03
	retscript


; "Past" version of Bipin who gives you a gasha seed
bipinScript3:
	loadscript scriptHlp.bipinScript3


; ==============================================================================
; INTERACID_ADLAR
; ==============================================================================
adlarScript:
	initcollisions
	jumptable_interactionbyte Interaction.var38
	.dw @firstMeeting
	.dw @nayruPossessed
	.dw @queenPosessed
	.dw @queenMissing
	.dw @queenBackToNormal

@firstMeeting:
	checkabutton
	showtext TX_3710
	orroomflag $40
@nayruPossessed:
	checkabutton
	showtext TX_3711
	jump2byte @nayruPossessed

@queenPosessed:
	checkabutton
	showtext TX_3712
	jump2byte @queenPosessed

@queenMissing:
	checkabutton
	showtext TX_3716
	jump2byte @queenMissing

@queenBackToNormal:
	checkabutton
	showtext TX_3713
	jump2byte @queenBackToNormal


; ==============================================================================
; INTERACID_LIBRARIAN
; ==============================================================================
librarianScript:
	makeabuttonsensitive
@loop:
	checkabutton
	showloadedtext
	jump2byte @loop


; ==============================================================================
; INTERACID_BLOSSOM
; ==============================================================================

; Blossom asking you to name her child
blossomScript0:
	initcollisions
	asm15 scriptHlp.checkc6e2BitSet $00
	jumpifinteractionbyteeq Interaction.var3b $01 @nameAlreadyGiven
@loop:
	checkabutton
	setdisabledobjectsto91
	showtextlowindex <TX_4400

@askForName:
	asm15 scriptHlp.blossom_openNameEntryMenu
	wait 30
	jumptable_memoryaddress wTextInputResult
	.dw @validName
	.dw @invalidName

@invalidName:
	showtextlowindex <TX_440a
	enableinput
	jump2byte @loop

@validName:
	showtextlowindex <TX_4407
	disableinput
	jumptable_memoryaddress wSelectedTextOption
	.dw @nameConfirmed
	.dw @askForName

@nameConfirmed:
	asm15 scriptHlp.blossom_decideInitialChildStatus
	asm15 scriptHlp.setc6e2Bit $00
	asm15 scriptHlp.setNextChildStage $01
	wait 30
	showtextlowindex <TX_4408
	enableinput

@nameAlreadyGiven:
	checkabutton
	showtextlowindex <TX_4409
	jump2byte @nameAlreadyGiven


; Blossom asking for money to see a doctor
blossomScript1:
	initcollisions
	asm15 scriptHlp.checkc6e2BitSet $01
	jumpifinteractionbyteeq Interaction.var3b $01 @alreadyGaveMoney
@loop:
	checkabutton
	setdisabledobjectsto91
	showtextlowindex <TX_440b
	jumptable_memoryaddress wSelectedTextOption
	.dw @selectedYes
	.dw @selectedNo
@selectedYes:
	wait 30
	showtextlowindex <TX_440c
	jumptable_memoryaddress wSelectedTextOption
	.dw @give150Rupees
	.dw @give50Rupees
	.dw @give10Rupees
	.dw @give1Rupee

@give150Rupees:
	asm15 scriptHlp.blossom_checkHasRupees RUPEEVAL_150
	jumpifinteractionbyteeq Interaction.var3c $01 @notEnoughRupees
	asm15 removeRupeeValue RUPEEVAL_150
	asm15 scriptHlp.blossom_addValueToChildStatus $08
	asm15 scriptHlp.setc6e2Bit $01
	asm15 scriptHlp.setNextChildStage $02
	setdisabledobjectsto00
@gave150RupeesLoop:
	showtextlowindex <TX_440d
	checkabutton
	jump2byte @gave150RupeesLoop

@give50Rupees:
	asm15 scriptHlp.blossom_checkHasRupees RUPEEVAL_050
	jumpifinteractionbyteeq Interaction.var3c $01 @notEnoughRupees
	asm15 removeRupeeValue RUPEEVAL_050
	asm15 scriptHlp.blossom_addValueToChildStatus $05
	asm15 scriptHlp.setc6e2Bit $01
	asm15 scriptHlp.setNextChildStage $02
	setdisabledobjectsto00
@gave50RupeesLoop:
	showtextlowindex <TX_440e
	checkabutton
	jump2byte @gave50RupeesLoop

@give10Rupees:
	asm15 scriptHlp.blossom_checkHasRupees RUPEEVAL_010
	jumpifinteractionbyteeq Interaction.var3c $01 @notEnoughRupees
	asm15 removeRupeeValue RUPEEVAL_010
	asm15 scriptHlp.blossom_addValueToChildStatus $02
	asm15 scriptHlp.setc6e2Bit $01
	asm15 scriptHlp.setNextChildStage $02
	setdisabledobjectsto00
@gave10RupeesLoop:
	showtextlowindex <TX_440f
	checkabutton
	jump2byte @gave10RupeesLoop

@give1Rupee:
	asm15 scriptHlp.blossom_checkHasRupees RUPEEVAL_001
	jumpifinteractionbyteeq Interaction.var3c $01 @notEnoughRupees
	asm15 removeRupeeValue RUPEEVAL_001
	asm15 scriptHlp.setc6e2Bit $01
	asm15 scriptHlp.setNextChildStage $02
	setdisabledobjectsto00
@gave1RupeeLoop:
	showtextlowindex <TX_4410
	checkabutton
	jump2byte @gave1RupeeLoop

@notEnoughRupees:
	wait 30
	showtextlowindex <TX_4432
	setdisabledobjectsto00
	jump2byte @loop

@selectedNo:
	wait 30
	showtextlowindex <TX_4411
	setdisabledobjectsto00
	jump2byte @loop

@alreadyGaveMoney:
	checkabutton
	showtextlowindex <TX_4431
	jump2byte @alreadyGaveMoney


; Blossom tells you that the baby has gotten better
blossomScript2:
	initcollisions
script4e08:
	checkabutton
	setdisabledobjectsto91
	showtextlowindex <TX_4412
	asm15 scriptHlp.setNextChildStage $03
	setdisabledobjectsto00
	jump2byte script4e08


; Blossom asks you how to get the baby to sleep
blossomScript3:
	initcollisions
	asm15 scriptHlp.checkc6e2BitSet $02
	jumpifinteractionbyteeq Interaction.var3b $01 @alreadyGaveAdvice
	checkabutton

	setdisabledobjectsto91
	showtextlowindex <TX_4413

	asm15 scriptHlp.setc6e2Bit $02
	asm15 scriptHlp.setNextChildStage $04

	jumptable_memoryaddress wSelectedTextOption
	.dw @sing
	.dw @play

@sing:
	wait 30
	showtextlowindex <TX_4414
	setdisabledobjectsto00
	jump2byte @alreadyGaveAdvice
@play:
	wait 30
	showtextlowindex <TX_4415
	asm15 scriptHlp.blossom_addValueToChildStatus $0a
	setdisabledobjectsto00

@alreadyGaveAdvice:
	checkabutton
	showtextlowindex <TX_4416
	jump2byte @alreadyGaveAdvice


; Blossom tells you that the child has grown
blossomScript4:
	rungenericnpclowindex <TX_4417


; Blossom says "we meet again" (linked file?)
blossomScript5:
	rungenericnpclowindex <TX_4418


; Blossom asks Link what he was like when he was a kid. (var03 is set to the child's
; current personality.)
blossomScript6:
	initcollisions
	asm15 scriptHlp.checkc6e2BitSet $03
	jumptable_interactionbyte Interaction.var03
	.dw @hyperactive
	.dw @shy
	.dw @curious

@hyperactive:
	jumpifinteractionbyteeq Interaction.var3b $01 @hyperactiveResponseReceived

@hyperactiveLoop1:
	checkabutton
	setdisabledobjectsto91
	showtextlowindex <TX_4419
	callscript @askAboutLinksBehaviour
	setdisabledobjectsto00
	jumpifinteractionbyteeq Interaction.var3a $00 @hyperactiveLoop1

@hyperactiveResponseReceived:
	checkabutton
	showtextlowindex <TX_4422
	jump2byte @hyperactiveResponseReceived


@shy:
	jumpifinteractionbyteeq Interaction.var3b $01 @shyReponseReceived

@shyLoop1:
	checkabutton
	setdisabledobjectsto91
	showtextlowindex <TX_441a
	callscript @askAboutLinksBehaviour
	setdisabledobjectsto00
	jumpifinteractionbyteeq Interaction.var3a $00 @shyLoop1

@shyReponseReceived:
	checkabutton
	showtextlowindex <TX_4423
	jump2byte @shyReponseReceived


@curious:
	jumpifinteractionbyteeq Interaction.var3b $01 @curiousResponseReceived

@curiousLoop1:
	checkabutton
	setdisabledobjectsto91
	showtextlowindex <TX_441b
	callscript @askAboutLinksBehaviour
	setdisabledobjectsto00
	jumpifinteractionbyteeq Interaction.var3a $00 @curiousLoop1

@curiousResponseReceived:
	checkabutton
	showtextlowindex <TX_4424
	jump2byte @curiousResponseReceived


; Blossom asks about how Link was as a child. She asks a few things before giving up.
; If Link said yes to something, var3a will be set to 1, indicating to the script that she
; got a response.
@askAboutLinksBehaviour:
	jumptable_memoryaddress wSelectedTextOption
	.dw @selectedYes_1
	.dw @selectedNo_1

@selectedYes_1:
	wait 30
	showtextlowindex <TX_441c
	asm15 scriptHlp.setc6e2Bit $03
	writeinteractionbyte Interaction.var3a $01
	asm15 scriptHlp.blossom_addValueToChildStatus $08
	retscript

@selectedNo_1: ; Quiet, perhaps?
	wait 30
	showtextlowindex <TX_441d
	jumptable_memoryaddress wSelectedTextOption
	.dw @selectedYes_2
	.dw @selectedNo_2

@selectedYes_2:
	wait 30
	showtextlowindex <TX_441e
	asm15 scriptHlp.setc6e2Bit $03
	writeinteractionbyte Interaction.var3a $01
	asm15 scriptHlp.blossom_addValueToChildStatus $05
	retscript

@selectedNo_2: ; Were you weird?
	wait 30
	showtextlowindex <TX_441f
	jumptable_memoryaddress wSelectedTextOption
	.dw @selectedYes_3
	.dw @selectedNo_3

@selectedYes_3:
	wait 30
	showtextlowindex <TX_4420
	asm15 scriptHlp.setc6e2Bit $03
	writeinteractionbyte Interaction.var3a $01
	asm15 scriptHlp.blossom_addValueToChildStatus $01
	retscript

@selectedNo_3: ; She gives up asking (but she'll ask again next time you talk)
	wait 30
	showtextlowindex <TX_4421
	wait 30
	retscript


; Blossom tells you about how her son's grown?
blossomScript7:
	jumptable_interactionbyte Interaction.var03
	.dw @slacker
	.dw @warrior
	.dw @arborist
	.dw @singer
@slacker:
	rungenericnpclowindex <TX_4425
@warrior:
	rungenericnpclowindex <TX_4426
@arborist:
	rungenericnpclowindex <TX_4427
@singer:
	rungenericnpclowindex <TX_4428


; Blossom tells you more specifically about her son's ambitions?
blossomScript8:
	jumptable_interactionbyte Interaction.var03
	.dw @slacker
	.dw @warrior
	.dw @arborist
	.dw @singer
@slacker:
	rungenericnpclowindex <TX_4429
@warrior:
	rungenericnpclowindex <TX_442a
@arborist:
	rungenericnpclowindex <TX_442b
@singer:
	rungenericnpclowindex <TX_442c


; Blossom tells you about what her son has accomplished?
blossomScript9:
	jumptable_interactionbyte Interaction.var03
	.dw @slacker
	.dw @warrior
	.dw @arborist
	.dw @singer
@slacker:
	rungenericnpclowindex <TX_442d
@warrior:
	rungenericnpclowindex <TX_442e
@arborist:
	rungenericnpclowindex <TX_442f
@singer:
	rungenericnpclowindex <TX_4430




; ==============================================================================
; INTERACID_VERAN_CUTSCENE_FACE
; ==============================================================================
veranFaceCutsceneScript:
	loadscript scriptHlp.veranFaceCutsceneScript


; ==============================================================================
; INTERACID_OLD_MAN_WITH_RUPEES
; ==============================================================================

oldManScript_givesRupees:
	initcollisions
	jumpifroomflagset $40 @alreadyGaveMoney
	checkabutton
	disableinput
	showtextlowindex <TX_3318
	asm15 scriptHlp.oldMan_giveRupees
	wait 8
	checkrupeedisplayupdated
	orroomflag $40
	enableinput

@alreadyGaveMoney:
	checkabutton
	showtextlowindex <TX_3319
	jump2byte @alreadyGaveMoney


oldManScript_takesRupees:
	initcollisions
	jumpifroomflagset $40 @alreadyTookMoney
	checkabutton
	disableinput
	showtextlowindex <TX_3315
	asm15 scriptHlp.oldMan_takeRupees
	jumpifinteractionbyteeq Interaction.var3f $00 @linkIsBroke
	wait 8
	checkrupeedisplayupdated
	orroomflag $40
	enableinput

@alreadyTookMoney:
	checkabutton
	showtextlowindex <TX_3316
	jump2byte @alreadyTookMoney

@linkIsBroke:
	wait 30
	showtextlowindex <TX_3317
	enableinput
	jump2byte @alreadyTookMoney


; ==============================================================================
; INTERACID_SHOOTING_GALLERY
; ==============================================================================

shootingGalleryScript_humanNpc:
	setcollisionradii $06 $16
	makeabuttonsensitive

@loop:
	checkabutton
	disableinput
	showtext TX_0800
	wait 30
	jumpiftextoptioneq $00 @repliedYes

@repliedNo:
	showtext TX_0802
	enableinput
	wait 30
	writeinteractionbyte Interaction.var31 $00
	jump2byte @loop

@tryAgain:
	disableinput
	showtext TX_081a
	wait 30
	jumpiftextoptioneq $00 @repliedYes
	jump2byte @repliedNo

@repliedYes:
	asm15 scriptHlp.shootingGallery_checkLinkHasRupees RUPEEVAL_10
	jumpifmemoryset $cddb $80 @enoughRupees

@notEnoughRupees:
	showtext TX_0803
	enableinput
	checkabutton
	jump2byte @notEnoughRupees

@enoughRupees:
	asm15 removeRupeeValue RUPEEVAL_10
	showtext TX_0801
	wait 30
	jumpiftextoptioneq $00 @beginGame

@giveExplanation:
	showtext TX_0804
	wait 30
	jumpiftextoptioneq $00 @beginGame
	jump2byte @giveExplanation

@beginGame:
	showtext TX_0805

_shootingGallery_fadeIntoGameWithSword:
	wait 40
	asm15 fadeoutToWhite
	checkpalettefadedone

	asm15 scriptHlp.shootingGallery_equipSword
	asm15 clearAllItemsAndPutLinkOnGround
	asm15 scriptHlp.shootingGallery_initLinkPosition
	asm15 scriptHlp.shootingGallery_setEntranceTiles $02
	wait 20
	asm15 fadeinFromWhite
	checkpalettefadedone

_shootingGallery_beginGame:
	setmusic MUS_MINIGAME
	wait 40
	wait 30
	asm15 scriptHlp.shootingGallery_beginGame
	setdisabledobjectsto00
	scriptend



shootingGalleryScript_goronNpc:
	setcollisionradii $06 $16
	makeabuttonsensitive

@loop:
	checkabutton
	jumpifmemoryeq wShootingGallery.disableGoronNpcs $01 @loop

	disableinput
	jumpifroomflagset $20 @normalGame

; playing for lava juice

	showtext TX_24d4
	wait 30
	jumpiftextoptioneq $00 @answeredYes

	; Answered no
	showtext TX_24d5
	enableinput
	wait 30
	writeinteractionbyte Interaction.var31 $00
	jump2byte @loop

@normalGame:
	showtext TX_24cf
	wait 30
	jumpiftextoptioneq $00 @answeredYes

@answeredNo:
	showtext TX_24d0
	enableinput
	wait 30
	writeinteractionbyte $71 $00
	jump2byte @loop

@tryAgain:
	disableinput
	showtext TX_24df
	wait 30
	jumpiftextoptioneq $00 @answeredYes
	jump2byte @answeredNo

@answeredYes:
	asm15 scriptHlp.shootingGallery_checkLinkHasRupees RUPEEVAL_20
	jumpifmemoryset $cddb $80 @enoughRupees

@notEnoughRupees:
	showtext TX_24d2
	enableinput
	checkabutton
	jump2byte @notEnoughRupees

@enoughRupees:
	disableinput
	asm15 removeRupeeValue RUPEEVAL_20
	showtext TX_24d1
	wait 30
	jumpiftextoptioneq $00 @beginGame

@giveExplanation:
	showtext TX_24d3
	wait 30
	jumpiftextoptioneq $00 @beginGame
	jump2byte @giveExplanation

@beginGame:
	showtext TX_24d6
	jump2byte _shootingGallery_fadeIntoGameWithSword



shootingGalleryScript_goronElderNpc:
	initcollisions
	jumpifglobalflagset GLOBALFLAG_76 @tellSecret
	jumpifglobalflagset GLOBALFLAG_6c @alreadyGaveSecret

@loop:
	checkabutton
	jumpifmemoryeq wShootingGallery.disableGoronNpcs $01 @loop
	disableinput
	showtext TX_3130
	wait 30
	jumpiftextoptioneq $00 @askForSecret
	showtext TX_3131
	enableinput
	jump2byte @loop

@askForSecret:
	askforsecret $08
	wait 30
	jumpifmemoryeq wTextInputResult $00 @validSecret
	showtext TX_3133
	enableinput
	jump2byte @loop

@validSecret:
	setglobalflag GLOBALFLAG_6c
	showtext TX_3132
	jump2byte @askedToTakeTest

@alreadyGaveSecret:
	checkabutton
	jumpifmemoryeq wShootingGallery.disableGoronNpcs $01 @alreadyGaveSecret
	disableinput
	showtext TX_313c
	jump2byte @askedToTakeTest

@tellSecret:
	checkabutton
	jumpifmemoryeq wShootingGallery.disableGoronNpcs $01 @tellSecret
	generatesecret $08
	showtext TX_313e
	jump2byte @tellSecret

; Parse the response to the goron asking you to take the test
@askedToTakeTest:
	wait 30
	jumpiftextoptioneq $00 @acceptedTest
	showtext TX_3134
	enableinput
	jump2byte @alreadyGaveSecret

@acceptedTest:
	showtext TX_3135
	wait 30
	jumpiftextoptioneq $00 @beginGame

@giveExplanation:
	showtext TX_3136
	wait 30
	jumpiftextoptioneq $01 @giveExplanation

@beginGame:
	showtext TX_3137
	wait 40
	asm15 fadeoutToWhite
	checkpalettefadedone
	asm15 scriptHlp.shootingGallery_equipBiggoronSword
	asm15 clearAllItemsAndPutLinkOnGround
	asm15 scriptHlp.shootingGallery_initLinkPosition
	asm15 scriptHlp.shootingGallery_setEntranceTiles $02
	wait 20
	asm15 fadeinFromWhite
	checkpalettefadedone
	jump2byte _shootingGallery_beginGame


shootingGalleryScript_hit1Blue:
	showtext TX_0807
	jump2byte _shootingGallery_printTotalPoints
shootingGalleryScript_hit1Fairy:
	showtext TX_0808
	jump2byte _shootingGallery_printTotalPoints
shootingGalleryScript_hit1Red:
	showtext TX_0809
	jump2byte _shootingGallery_printTotalPoints
shootingGalleryScript_hit1Imp:
	showtext TX_080a
	jump2byte _shootingGallery_printTotalPoints
shootingGalleryScript_hit2Blue:
	showtext TX_080b
	jump2byte _shootingGallery_printTotalPoints
shootingGalleryScript_hit2Red:
	showtext TX_080c
	jump2byte _shootingGallery_printTotalPoints
shootingGalleryScript_hit1Blue1Fairy:
	showtext TX_080e
	jump2byte _shootingGallery_printTotalPoints
shootingGalleryScript_hit1Red1Blue:
	showtext TX_080d
	jump2byte _shootingGallery_printTotalPoints
shootingGalleryScript_hit1Blue1Imp:
	showtext TX_080f
	jump2byte _shootingGallery_printTotalPoints
shootingGalleryScript_hit1Red1Fairy:
	showtext TX_0810
	jump2byte _shootingGallery_printTotalPoints
shootingGalleryScript_hit1Fairy1Imp:
	showtext TX_0811
	jump2byte _shootingGallery_printTotalPoints
shootingGalleryScript_hit1Red1Imp:
	showtext TX_0812
	jump2byte _shootingGallery_printTotalPoints
shootingGalleryScript_hitNothing:
	showtext TX_0806
	jump2byte _shootingGallery_printTotalPoints
shootingGalleryScript_strike:
	showtext TX_081c

_shootingGallery_printTotalPoints:
	wait 15
	jumpifinteractionbyteeq Interaction.var3f 10 @gameDone ; Is this the 10th round?

	showtext TX_0813
	setdisabledobjectsto00
	scriptend

@gameDone:
	jumpifinteractionbyteeq $42 $01 @goronGallery

	showtext TX_0814
	setdisabledobjectsto00
	scriptend

@goronGallery:
	showtext TX_24d7
	setdisabledobjectsto00
	scriptend



shootingGalleryScript_humanNpc_gameDone:
	loadscript scriptHlp.shootingGalleryScript_humanNpc_gameDone

shootingGalleryScript_goronNpc_gameDone:
	loadscript scriptHlp.shootingGalleryScript_goronNpc_gameDone

shootingGalleryScript_goronElderNpc_gameDone:
	disableinput
	wait 40
	asm15 fadeoutToWhite
	checkpalettefadedone
	asm15 scriptHlp.shootingGallery_restoreEquips
	asm15 scriptHlp.shootingGallery_setEntranceTiles $00
	asm15 scriptHlp.shootingGallery_removeAllTargets
	asm15 clearAllItemsAndPutLinkOnGround
	asm15 scriptHlp.shootingGallery_initLinkPositionAfterBiggoronGame

	wait 20
	asm15 fadeinFromWhite
	checkpalettefadedone
	setmusic $ff
	wait 40

	asm15 scriptHlp.shootingGallery_cpScore $08
	jumpifmemoryset $cddb $80 @giveBiggoronSword

	; Not enough points
	showtext TX_3138
	wait 30
	jumpiftextoptioneq $00 @end2
	showtext TX_3139
	enableinput

; If you talk to him, he asks if you want to play again
@npcLoop:
	checkabutton
	jumpifmemoryeq wShootingGallery.disableGoronNpcs $01 shootingGalleryScript_goronElderNpc@alreadyGaveSecret
	disableinput
	showtext TX_313c
	wait 30
	jumpiftextoptioneq $00 @playAgain
	showtext TX_3134
	enableinput
	jump2byte @npcLoop

@playAgain:
	showtext TX_3135
	wait 30
	jumpiftextoptioneq $00 @end1

@giveExplanation:
	showtext TX_3136
	wait 30
	jumpiftextoptioneq $01 @giveExplanation
@end1:
	scriptend

@giveBiggoronSword:
	showtext TX_313a
	wait 30
	giveitem TREASURE_BIGGORON_SWORD $00
	wait 30
	setglobalflag GLOBALFLAG_76
	generatesecret $08
	showtext TX_313b
	enableinput
	jump2byte shootingGalleryScript_goronElderNpc@tellSecret
@end2:
	scriptend



; ==============================================================================
; INTERACID_IMPA
; ==============================================================================

script518b:
	asm15 scriptHlp.createSparkle
	wait 30
	asm15 scriptHlp.func_50e4
	wait 10
	playsound $b4
	asm15 fadeoutToWhite
	wait 20
	playsound $b4
	asm15 fadeoutToWhite
	wait 20
	playsound $b4
	asm15 fadeoutToWhite
	checkpalettefadedone
	wait 20
	asm15 fadeinFromWhiteWithDelay $04
	checkpalettefadedone
	retscript
script51ac:
	asm15 $5191
script51af:
	asm15 $519e
	jumpifmemoryset $cddb $80 script51ba
	jump2byte script51af
script51ba:
	retscript


; Subid 0: wait for signal from $cfd0 (link has approached?), then move toward Link.
impaScript0:
	checkmemoryeq $cfd0 $01
	wait 210
	showtextdifferentforlinked TX_0102 TX_0103
	wait 30
	setspeed SPEED_080
	movenpcdown $20
	orroomflag $40
	scriptend

impaScript_moveAwayFromRock:
	checkmemoryeq $cfd0 $03
	setanimation $02
	wait 10
	showtext TX_0106
	wait 30
	setanimation $01
	setangle $18
	setspeed SPEED_080
	applyspeed $21
	wait 30
	showtext TX_0107
	wait 30
	applyspeed $21
	wait 30
	showtext TX_0108
	wait 30
	writememory $cfd0 $04
	scriptend

impaScript_waitForRockToBeMoved:
	rungenericnpc TX_010b

impaScript_rockJustMoved:
	loadscript scriptHlp.impaScript_rockJustMoved
script51f8:
	setanimation $02
	checkmemoryeq $cfd0 $0d
	wait 30
	playsound $fa
	wait 30
	setspeed SPEED_100
	movenpcright $20
	wait 8
	movenpcup $10
	wait 30
	playsound $2f
	setanimation $04
	wait 240
	showtext $5600
	writememory $cfd0 $0e
	wait 60
	setanimation $00
	wait 60
	showtext $5606
	wait 10
	setanimation $07
	setangle $16
	setspeed SPEED_080
	applyspeed $48
	writememory $cfd0 $0f
	scriptend
impaScript1:
	wait 120
	setanimation $02
	asm15 $5300
	wait 60
	setanimation $03
	wait 50
	setanimation $01
	wait 30
	setanimation $03
	wait 10
	setanimation $01
	wait 60
	showtext $0110
	wait 30
	setanimation $03
	wait 30
	showtextdifferentforlinked TX_0112 TX_0113
	wait 30
	setanimation $01
	showtextdifferentforlinked TX_0115 TX_0116
	wait 30
	jumpifmemoryeq $cc01 $01 script525d
	giveitem $0500
	jump2byte script5260
script525d:
	giveitem $0100
script5260:
	wait 30
	asm15 scriptHlp.func_5155 $03
	wait 30
	showtext $0117
	wait 30
	setspeed SPEED_100
	movenpcright $41
	wait 8
	movenpcdown $21
	wait 30
	setmusic $ff
	wait 30
	enableinput
	setglobalflag $0a
	scriptend
impaScript2:
	checkpalettefadedone
	wait 90
	setspeed SPEED_200
	movenpcup $20
	addinteractionbyte $78 $1e
	addinteractionbyte $45 $01
	checkmemoryeq $cfc0 $05
	setanimation $08
	checkinteractionbyteeq $61 $01
	writememory $cfc0 $06
	scriptend
impaScript3:
	checkmemoryeq $cfc0 $05
	setspeed SPEED_100
	movenpcleft $10
	setanimation $02
	wait 6
	movenpcdown $10
	setanimation $03
	wait 6
	movenpcleft $12
	setanimation $00
	wait 30
	showtext $3d08
	wait 128
	writememory $cfc0 $06
	scriptend
impaScript4:
	loadscript scriptHlp.script15_5344
impaScript5:
	loadscript scriptHlp.script15_536e
impaScript6:
	checkpalettefadedone
	wait 60
	setspeed SPEED_080
	movenpcdown $61
	setspeed SPEED_0c0
	checkmemoryeq $cfd1 $01
	wait 8
	movenpcdown $2b
	scriptend
impaScript7:
	loadscript scriptHlp.script15_53ae
impaScript8:
	checkcfc0bit 0
	wait 30
	asm15 $5854 $1e
	checkcfc0bit 3
	setspeed SPEED_200
	setanimation $03
	setangle $13
	applyspeed $31
	xorcfc0bit 4
	scriptend
impaScript9:
	checkmemoryeq $cfd0 $11
	playsound $f0
	showtext $0130
	writeinteractionbyte $78 $01
	wait 60
	setspeed SPEED_180
	movenpcleft $30
	wait 4
	setanimation $02
	wait 8
	callscript script51ac
	wait 10
	asm15 scriptHlp.func_5155 $00
	wait 10
	asm15 $530c
	writememory $cfd0 $12
	scriptend




script5307:
	scriptend
script5308:
	initcollisions
script5309:
	checkabutton
	jumpifglobalflagset $20 script5314
	showtextlowindex $06
	setglobalflag $20
	jump2byte script5309
script5314:
	jumpifitemobtained $51 script531c
	showtextlowindex $07
	jump2byte script5309
script531c:
	setdisabledobjectsto11
	disablemenu
	showtextlowindex $08
	asm15 $543a
	wait 60
	scriptend

; ==============================================================================
; INTERACID_CHILD
; ==============================================================================

; For a summary of the child's behaviour, see:
; http://wiki.zeldahacking.net/oracle/Bipin_and_Blossom's_son

childScript00:
	scriptend

childScript_stage4_hyperactive:
	initcollisions
@loop:
	checkabutton
	showtext TX_4700
	jump2byte @loop

childScript_stage4_shy:
	initcollisions
@loop:
	checkabutton
	showtext TX_4200
	jump2byte @loop

childScript_stage4_curious:
	initcollisions
@loop:
	checkabutton
	showtext TX_4900
	jump2byte @loop


childScript_stage5_hyperactive:
	initcollisions
@loop:
	checkabutton
	showtext TX_4701
	asm15 scriptHlp.setNextChildStage $06
	jump2byte @loop

childScript_stage5_shy:
	initcollisions
@loop:
	checkabutton
	showtext TX_4201
	asm15 scriptHlp.setNextChildStage $06
	jump2byte @loop

childScript_stage5_curious:
	initcollisions
@loop:
	checkabutton
	showtext TX_4901
	asm15 scriptHlp.setNextChildStage $06
	jump2byte @loop


; Stage 6: the child asks a question. The question differs based on his personality, but
; the result is always the same: wChildStatus is incremented by 4 if you answer yes.

childScript_stage6_hyperactive:
	initcollisions
	asm15 scriptHlp.checkc6e2BitSet $04
	jumpifinteractionbyteeq Interaction.var3b $01 @alreadyAnswered
	checkabutton
	disableinput
	showtext TX_4702
	asm15 scriptHlp.setc6e2Bit $04
	asm15 scriptHlp.setNextChildStage $07
	jumptable_memoryaddress wSelectedTextOption
	.dw @answeredYes
	.dw @answeredNo

@answeredYes:
	wait 30
	showtext TX_4703
	asm15 scriptHlp.child_addValueToChildStatus $04
	enableinput
	jump2byte @alreadyAnswered

@answeredNo:
	wait 30
	showtext TX_4704
	enableinput

@alreadyAnswered:
	checkabutton
	showtext TX_4705
	jump2byte @alreadyAnswered


childScript_stage6_shy:
	initcollisions
	asm15 scriptHlp.checkc6e2BitSet $04
	jumpifinteractionbyteeq Interaction.var3b $01 @alreadyAnswered
	checkabutton
	disableinput
	showtext TX_4202
	asm15 scriptHlp.setc6e2Bit $04
	asm15 scriptHlp.setNextChildStage $07
	jumptable_memoryaddress wSelectedTextOption
	.dw @answeredYes
	.dw @answeredNo

@answeredYes:
	wait 30
	showtext TX_4203
	asm15 scriptHlp.child_addValueToChildStatus $04
	enableinput
	jump2byte @alreadyAnswered

@answeredNo:
	wait 30
	showtext TX_4204
	enableinput

@alreadyAnswered:
	checkabutton
	showtext TX_4205
	jump2byte @alreadyAnswered


childScript_stage6_curious:
	initcollisions
	asm15 scriptHlp.checkc6e2BitSet $04
	jumpifinteractionbyteeq Interaction.var3b $01 @alreadyAnswered
	checkabutton
	disableinput
	showtext TX_4902
	asm15 scriptHlp.setc6e2Bit $04
	asm15 scriptHlp.setNextChildStage $07
	jumptable_memoryaddress wSelectedTextOption
	.dw @answeredChicken
	.dw @answeredEgg

@answeredChicken:
	wait 30
	showtext TX_4903
	asm15 scriptHlp.child_addValueToChildStatus $04
	enableinput
	jump2byte @alreadyAnswered

@answeredEgg:
	wait 30
	showtext TX_4904
	enableinput

@alreadyAnswered:
	checkabutton
	showtext TX_4905
	jump2byte @alreadyAnswered


; Stage 7: just says some text.

childScript_stage7_slacker:
	initcollisions
@loop:
	checkabutton
	showtext TX_4b00
	asm15 scriptHlp.setNextChildStage $08
	jump2byte @loop

childScript_stage7_warrior:
	initcollisions
@loop:
	checkabutton
	showtext TX_4a00
	asm15 scriptHlp.setNextChildStage $08
	jump2byte @loop

childScript_stage7_arborist:
	initcollisions
@loop:
	checkabutton
	showtext TX_4800
	asm15 scriptHlp.setNextChildStage $08
	jump2byte @loop

childScript_stage7_singer:
	initcollisions
@loop:
	checkabutton
	showtext TX_4600
	asm15 scriptHlp.setNextChildStage $08
	jump2byte @loop


; Stage 8: asks a question or makes a request. This affects what he will do in stage 9.

childScript_stage8_slacker:
	initcollisions
	asm15 scriptHlp.checkc6e2BitSet $05
	jumpifinteractionbyteeq Interaction.var3b $01 @alreadyAnswered

@loop:
	checkabutton
	disableinput
	showtext TX_4b01
	jumptable_memoryaddress wSelectedTextOption
	.dw @answeredYes
	.dw @answeredNo

@answeredYes:
	wait 30
	showtext TX_4b02
	jumptable_memoryaddress wSelectedTextOption
	.dw @answered100Rupees
	.dw @answered50Rupees
	.dw @answered10Rupees
	.dw @answered0Rupees

@answered100Rupees:
	asm15 scriptHlp.child_checkHasRupees RUPEEVAL_100
	jumpifinteractionbyteeq Interaction.var3c $01 @notEnoughRupees
	asm15 removeRupeeValue RUPEEVAL_100
	asm15 scriptHlp.child_setStage8Response $00
	asm15 scriptHlp.setc6e2Bit $05
	asm15 scriptHlp.setNextChildStage $09
	wait 30
	enableinput
@answered100Loop:
	showtext TX_4b04
	checkabutton
	jump2byte @answered100Loop

@answered50Rupees:
	asm15 scriptHlp.child_checkHasRupees RUPEEVAL_050
	jumpifinteractionbyteeq Interaction.var3c $01 @notEnoughRupees
	asm15 removeRupeeValue RUPEEVAL_050
	asm15 scriptHlp.child_setStage8Response $01
	asm15 scriptHlp.setc6e2Bit $05
	asm15 scriptHlp.setNextChildStage $09
	wait 30
	enableinput
@answered50Loop:
	showtext TX_4b05
	checkabutton
	jump2byte @answered50Loop

@answered10Rupees:
	asm15 scriptHlp.child_checkHasRupees RUPEEVAL_010
	jumpifinteractionbyteeq Interaction.var3c $01 @notEnoughRupees
	asm15 removeRupeeValue RUPEEVAL_010
	asm15 scriptHlp.child_setStage8Response $02
	asm15 scriptHlp.setc6e2Bit $05
	asm15 scriptHlp.setNextChildStage $09
	wait 30
	enableinput
@answered10Loop:
	showtext TX_4b06
	checkabutton
	jump2byte @answered10Loop

@answered0Rupees: ; He takes 1 rupee anyway...
	asm15 scriptHlp.child_checkHasRupees RUPEEVAL_001
	jumpifinteractionbyteeq Interaction.var3c $01 @notEnoughRupees
	asm15 removeRupeeValue RUPEEVAL_001
	asm15 scriptHlp.child_setStage8Response $03
	asm15 scriptHlp.setc6e2Bit $05
	asm15 scriptHlp.setNextChildStage $09
	wait 30
	enableinput
@answered0Loop:
	showtext TX_4b07
	checkabutton
	jump2byte @answered0Loop

@notEnoughRupees:
	wait 30
	showtext TX_4b08
	enableinput
	jump2byte @loop

@answeredNo:
	wait 30
	showtext TX_4b03
	enableinput
	jump2byte @loop

@alreadyAnswered:
	checkabutton
	showtext TX_4b09
	jump2byte @alreadyAnswered


; Asks Link what will make him mightiest.
childScript_stage8_warrior:
	initcollisions
	asm15 scriptHlp.checkc6e2BitSet $05
	jumpifinteractionbyteeq Interaction.var3b $01 @alreadyAnswered
	checkabutton
	disableinput
	showtext TX_4a01
	jumptable_memoryaddress wSelectedTextOption
	.dw @answeredDailyTraining
	.dw @answeredNo_1

@answeredNo_1:
	wait 30
	showtext TX_4a02
	jumptable_memoryaddress wSelectedTextOption
	.dw @answeredNaturalTalent
	.dw @answeredNo_2

@answeredNo_2:
	wait 30
	showtext TX_4a03
	jumptable_memoryaddress wSelectedTextOption
	.dw @answeredCaringHeart
	.dw @answeredNo_3

@answeredNo_3: ; He gives up asking
	asm15 scriptHlp.child_setStage8Response $03
	asm15 scriptHlp.setc6e2Bit $05
	asm15 scriptHlp.setNextChildStage $09
	wait 30
	showtext TX_4a04
	enableinput
	wait 30
	jump2byte @alreadyAnswered

@answeredDailyTraining:
	asm15 scriptHlp.child_setStage8Response $00
	jump2byte @gaveResponse

@answeredNaturalTalent:
	asm15 scriptHlp.child_setStage8Response $01
	jump2byte @gaveResponse

@answeredCaringHeart:
	asm15 scriptHlp.child_setStage8Response $02

@gaveResponse:
	asm15 scriptHlp.setc6e2Bit $05
	asm15 scriptHlp.setNextChildStage $09
	wait 30
	showtext TX_4a05
	wait 30
	enableinput

@alreadyAnswered:
	checkabutton
	showtext TX_4a08
	jump2byte @alreadyAnswered


; Gives Link a gasha seed.
childScript_stage8_arborist:
	initcollisions
	asm15 scriptHlp.checkc6e2BitSet $05
	jumpifinteractionbyteeq Interaction.var3b $01 @alreadyGaveSeed

	checkabutton
	disableinput
	showtext TX_4801
	giveitem TREASURE_GASHA_SEED $03
	asm15 scriptHlp.setc6e2Bit $05
	asm15 scriptHlp.setNextChildStage $09
	wait 30
	showtext TX_4802
	wait 30
	enableinput

@alreadyGaveSeed:
	checkabutton
	showtext TX_4803
	jump2byte @alreadyGaveSeed


; Asks link what's more important, love or courage.
childScript_stage8_singer:
	initcollisions
	asm15 scriptHlp.checkc6e2BitSet $05
	jumpifinteractionbyteeq Interaction.var3b $01 @alreadyAnswered

	checkabutton
	disableinput
	showtext TX_4601
	asm15 scriptHlp.child_setStage8ResponseToSelectedTextOption $00
	asm15 scriptHlp.setc6e2Bit $05
	asm15 scriptHlp.setNextChildStage $09
	wait 30
	enableinput
	jump2byte @showResponseText

@alreadyAnswered:
	checkabutton
@showResponseText:
	showtext TX_4602
	jump2byte @alreadyAnswered


; Stage 9: the child gives a reward based on your response in stage 8.

childScript_stage9_slacker:
	initcollisions
	asm15 scriptHlp.checkc6e2BitSet $06
	jumpifinteractionbyteeq Interaction.var3b $01 @alreadyGaveReward
	checkabutton
	disableinput
	showtext TX_4b0a
	asm15 scriptHlp.setc6e2Bit $06
	wait 30
	jumptable_memoryaddress wChildStage8Response
	.dw @fillSatchel
	.dw @give200Rupees
	.dw @giveGashaSeed
	.dw @give10Bombs

@fillSatchel:
	asm15 refillSeedSatchel
	showtext TX_0052
	jump2byte @justGaveReward

@give200Rupees:
	asm15 scriptHlp.child_giveRupees RUPEEVAL_200
	showtext TX_0009
	jump2byte @justGaveReward

@giveGashaSeed:
	giveitem TREASURE_GASHA_SEED $03
	jump2byte @justGaveReward

@give10Bombs:
	giveitem TREASURE_BOMBS $02

@justGaveReward:
	wait 30
	enableinput
	jump2byte @showTextAfterGiving

@alreadyGaveReward:
	checkabutton
@showTextAfterGiving:
	showtext TX_4b0b
	jump2byte @alreadyGaveReward


childScript_stage9_warrior:
	initcollisions
	asm15 scriptHlp.checkc6e2BitSet $06
	jumpifinteractionbyteeq Interaction.var3b $01 @alreadyGaveReward
	checkabutton
	disableinput
	showtext TX_4a06
	wait 30
	showtext TX_4a07
	asm15 scriptHlp.setc6e2Bit $06
	wait 30
	jumptable_memoryaddress wChildStage8Response
	.dw @give100Rupees
	.dw @give1Heart
	.dw @restoreHealth
	.dw @give1Rupee

@give100Rupees:
	asm15 scriptHlp.child_giveRupees RUPEEVAL_100
	showtext TX_0007
	jump2byte @justGaveReward

@give1Heart:
	asm15 scriptHlp.child_giveOneHeart $01
	showtext TX_0051
	jump2byte @justGaveReward

@restoreHealth:
	asm15 scriptHlp.child_giveHeartRefill
	showtext TX_0053
	jump2byte @justGaveReward

@give1Rupee:
	asm15 scriptHlp.child_giveRupees RUPEEVAL_001
	showtext TX_0001

@justGaveReward:
	wait 30
	enableinput
	jump2byte @showTextAfterGiving

@alreadyGaveReward:
	checkabutton
@showTextAfterGiving:
	showtext TX_4a08
	jump2byte @alreadyGaveReward


childScript_stage9_arborist:
	initcollisions
@loop:
	checkabutton
	disableinput
	showtext TX_4804
	wait 30
	callscript @showTip
	enableinput
	jump2byte @loop

@showTip:
	writeinteractionbyte Interaction.textID+1 >TX_4800
	getrandombits        Interaction.textID   $07
	addinteractionbyte   Interaction.textID   <TX_4805
	showloadedtext
	retscript


childScript_stage9_singer:
	initcollisions
script5639:
	checkabutton
	disableinput
	showtext TX_4603
	jumptable_memoryaddress wSelectedTextOption
	.dw script5645
	.dw script5653
script5645:
	asm15 scriptHlp.child_playMusic
	asm15 scriptHlp.child_giveHeartRefill
	wait 30
	enableinput
script564d:
	showtext TX_4604
	checkabutton
	jump2byte script564d
script5653:
	wait 30
	showtext TX_4605
	enableinput
	jump2byte script5639




script565a:
	setanimation $02
	checkmemoryeq $cfd0 $0a
	wait 10
	setspeed SPEED_040
	movenpcdown $20
	wait 30
	showtext $1d00
	wait 30
	writememory $cfd0 $0b
	checkmemoryeq $cfd0 $0c
	asm15 $5632 $00
	wait 40
	showtext $1d22
	wait 30
	writememory $cfd0 $0d
	checkmemoryeq $cfd0 $0f
	setanimation $02
	checkmemoryeq $cfd0 $13
	setspeed SPEED_040
	setangle $00
	applyspeed $20
	checkmemoryeq $cfd0 $15
	wait 120
	writememory $cfd0 $16
	wait 30
	setangle $10
	setspeed SPEED_020
	applyspeed $81
	setcoords $28 $78
	wait 210
	setanimation $05
	writeinteractionbyte $5c $06
	playsound $ab
	wait 60
	setanimation $02
	writememory $cfd0 $17
	orroomflag $40
	scriptend
script56b5:
	setanimation $02
	checkmemoryeq $cfd0 $1c
	wait 40
	showtext $5605
	wait 60
	setspeed SPEED_100
	movenpcup $11
	writeinteractionbyte $7d $01
	playsound $95
	wait 120
	writememory $cfd0 $1d
	scriptend
script56cf:
	loadscript scriptHlp.script15_548d
script56d3:
	checkmemoryeq $cfd0 $01
	asm15 objectSetVisiblec2
	checkpalettefadedone
	wait 30
	setanimation $02
	wait 90
	showtext $1d06
	wait 30
	writememory $cfd0 $02
	scriptend
script56e8:
	loadscript scriptHlp.script15_54ce
script56ec:
	wait 1
	asm15 $5615 $03
	jumpifmemoryeq $cfd0 $09 script56f9
	jump2byte script56ec
script56f9:
	wait 60
	setanimation $02
	checkmemoryeq $cfd0 $0a
	wait 60
	asm15 scriptHlp.func_5155 $00
	wait 40
	showtext $1d08
	wait 20
	setspeed SPEED_0c0
	movenpcright $14
	wait 8
	movenpcdown $4c
	asm15 scriptHlp.func_5155 $02
	writememory $cfd0 $0b
	scriptend
script571a:
	loadscript scriptHlp.script15_54fd
script571e:
	checkpalettefadedone
	wait 30
	setspeed SPEED_100
	movenpcup $19
	setspeed SPEED_080
	movenpcup $21
	setspeed SPEED_100
	movenpcup $1a
	wait 4
	movenpcleft $11
	wait 4
	setanimation $00
	checkmemoryeq $cfd0 $06
	movenpcup $10
	wait 180
	writememory $cfd0 $07
	scriptend
script573e:
	checkmemoryeq $cfd0 $0f
	setanimation $01
	wait 20
	showtext $1d0d
	wait 120
	writememory $cfd0 $10
	scriptend
script574e:
	checkmemoryeq $cfc0 $01
	asm15 objectSetVisible82
	checkpalettefadedone
	wait 60
	setanimation $02
	checkmemoryeq $cfc0 $05
	setanimation $03
	scriptend
script5760:
	loadscript scriptHlp.script15_553b
script5764:
	checkmemoryeq $cfc0 $03
	setangle $18
	setspeed SPEED_100
	applyspeed $20
	wait 6
	setanimation $00
	wait 30
	showtext $3d0a
	wait 30
	setanimation $01
	wait 6
	movenpcright $20
	wait 10
	setanimation $03
	writememory $cfc0 $04
	wait 128
	scriptend
script5787:
	wait 10
	setspeed SPEED_100
	movenpcdown $39
	checkcfc0bit 1
	setspeed SPEED_080
	movenpcdown $11
	showtext $1d12
	wait 16
	xorcfc0bit 2
	checkcfc0bit 3
	wait 8
	showtext $1d13
	xorcfc0bit 4
	wait 30
	setspeed SPEED_100
	movenpcup $41
	scriptend
script57a3:
	checkmemoryeq $cfd0 $01
	setanimation $00
	checkmemoryeq $cfd0 $02
	setanimation $01
	checkmemoryeq $cfd0 $03
	setanimation $02
	checkmemoryeq $cfd0 $05
	setanimation $00
	checkmemoryeq $cfd0 $06
	setspeed SPEED_100
	movenpcup $11
	setanimation $01
	writememory $d008 $03
	showtext $1d12
	wait 8
	writememory $cfd0 $07
	checkmemoryeq $cfd0 $08
	writememory $d008 $00
	movenpcup $11
	movenpcright $11
	movenpcup $41
	scriptend
script57e0:
	loadscript scriptHlp.script15_5575
script57e4:
	loadscript scriptHlp.script15_55e5
script57e8:
	loadscript scriptHlp.script15_55fa
script57ec:
	wait 30
	callscript script51ac
	wait 30
	showtext $2a00
	wait 30
	writememory $cfd0 $0a
	checkmemoryeq $cfd0 $0b
	asm15 $5632 $01
	callscript script51ac
	wait 10
	showtext $2a22
	wait 30
	writememory $cfd0 $0c
	checkmemoryeq $cfd0 $0f
	setanimation $02
	writeinteractionbyte $48 $02
	checkmemoryeq $cfd0 $11
	setspeed SPEED_180
	playsound $75
	movenpcdown $16
	playsound $75
script5822:
	wait 1
	asm15 $5613
	jumpifmemoryeq $cfd0 $15 script582e
	jump2byte script5822
script582e:
	setanimation $00
	wait 220
	setspeed SPEED_020
	setangle $10
	applyspeed $81
	checkmemoryeq $cfd0 $17
	wait 120
	setspeed SPEED_100
	movenpcleft $10
	wait 6
	asm15 $563a
	movenpcup $18
	wait 30
	setanimation $04
	playsound $74
	wait 60
	showtext $2a01
	wait 30
	showtext $5603
	wait 60
	setanimation $00
	writeinteractionbyte $7f $ff
	writememory $cc1e $31
	writememory $cc18 $01
	setspeed SPEED_020
	setangle $10
	applyspeed $81
	wait 30
	showtext $5604
	wait 60
	writememory $cfd0 $18
	checkmemoryeq $cfd2 $ff
	setanimation $03
	checkmemoryeq $cfd0 $1b
	wait 20
	setspeed SPEED_100
	movenpcup $30
	wait 6
	movenpcleft $31
	writememory $cfd0 $1c
	checkmemoryeq $cfd0 $1d
	wait 120
	scriptend
script588f:
	loadscript scriptHlp.script15_56c9
script5893:
	setmusic $35
	setspeed SPEED_200
	setanimation $03
	wait 40
	movenpcleft $1d
	writeinteractionbyte $7f $01
	wait 40
	callscript script51ac
	wait 40
	showtext $2a08
	wait 40
	writeinteractionbyte $7f $00
	setspeed SPEED_200
	movenpcleft $45
	writememory $cfc0 $01
	setmusic $ff
	scriptend
script58b6:
	loadscript scriptHlp.script15_5716
script58ba:
	checkmemoryeq $cfd0 $01
	asm15 objectSetVisiblec2
	writeinteractionbyte $60 $7f
	checkpalettefadedone
	wait 30
	setanimation $01
	scriptend
script58c9:
	checkmemoryeq $cfd0 $04
	setspeed SPEED_100
	movenpcdown $13
	wait 6
	movenpcright $0a
	asm15 scriptHlp.func_5155 $03
	wait 30
	showtext $2a0e
	wait 30
	asm15 scriptHlp.func_5155 $00
	setanimation $00
	writememory $cfd0 $05
	scriptend
script58e9:
	wait 1
	asm15 $5615 $03
	jumpifmemoryeq $cfd0 $09 script58f6
	jump2byte script58e9
script58f6:
	wait 60
	setmusic $ff
	wait 60
	setanimation $01
	asm15 scriptHlp.func_5155 $03
	wait 20
	showtextdifferentforlinked TX_2a0f TX_2a10
	wait 20
	setspeed SPEED_200
	movenpcdown $18
	asm15 scriptHlp.func_5155 $02
	writememory $cfd0 $0a
	scriptend
script5913:
	wait 7
	setanimation $03
	setspeed SPEED_080
	setangle $08
	applyspeed $20
	checkinteractionbyteeq $7e $01
	wait 10
	movenpcleft $10
	asm15 scriptHlp.func_5155 $01
	wait 10
	showtext $2a11
	wait 20
	writememory $cfd0 $03
	checkmemoryeq $cfd0 $04
	wait 50
	setspeed SPEED_100
	movenpcleft $10
	wait 6
	movenpcdown $28
	wait 60
	writememory $cfd0 $05
	scriptend
script5944:
	checkpalettefadedone
	wait 30
	setspeed SPEED_100
	movenpcup $37
	setspeed SPEED_080
	movenpcup $21
	wait 20
	setspeed SPEED_200
	movenpcup $15
	wait 30
	showtext $2a12
	wait 30
	writememory $cfd0 $06
	checkinteractionbyteeq $7e $01
	wait 10
	showtext $2a13
	wait 60
	writememory $cfd0 $09
	scriptend
script5969:
	checkpalettefadedone
	wait 60
	setanimation $01
	wait 10
	asm15 scriptHlp.func_5155 $03
	wait 10
	showtext $2a14
	wait 60
	jumpifmemoryeq $cc01 $01 script59a1
	wait 20
	setanimation $00
	asm15 scriptHlp.func_5155 $00
	wait 20
	writememory $cfd0 $0c
	checkmemoryeq $cfd0 $0d
	showtext $2a15
	wait 10
	writememory $cfd0 $0e
	checkmemoryeq $cfd0 $0f
	wait 10
	setanimation $03
	asm15 scriptHlp.func_5155 $03
	scriptend
script59a1:
	writememory $cfd0 $11
	scriptend
script59a6:
	checkmemoryeq $cfc0 $01
	asm15 objectSetVisible82
	checkmemoryeq $cfc0 $02
	wait 40
	setanimation $00
	wait 20
	asm15 $5656 $28
	wait 60
	writememory $cfc0 $03
	setspeed SPEED_180
	setangle $05
	applyspeed $1e
	wait 60
	setanimation $02
	wait 30
	addinteractionbyte $45 $01
	checkinteractionbyteeq $7e $01
	wait 60
	writememory $cfc0 $05
	scriptend
script59d4:
	checkpalettefadedone
	wait 73
	setanimation $07
	wait 45
	setanimation $03
	wait 90
	setanimation $05
	wait 20
	setanimation $06
	wait 170
	setanimation $0b
	wait 40
	scriptend
script59e9:
	wait 30
	asm15 $5647
	wait 30
	showtext $2a16
	wait 15
	showtext $2a17
	wait 30
	showtext $2a18
	movenpcup $28
	asm15 setGlobalFlag $32
	setmusic $ff
	scriptend
script5a02:
	wait 8
	showtext $2a19
	wait 16
	writememory $d008 $02
	movenpcdown $18
	asm15 setGlobalFlag $45
	scriptend
script5a13:
	asm15 $5656 $1e
	wait 30
	writememory $cfd0 $01
	setspeed SPEED_100
	movenpcup $29
	checkinteractionbyteeq $45 $03
	wait 8
	showtext $2a19
	wait 8
	movenpcdown $29
	writememory $cfd0 $02
	setanimation $03
	wait 45
	setanimation $02
	wait 30
	writememory $cfd0 $03
	setspeed SPEED_180
	movenpcdown $29
	wait 30
	writememory $cfd0 $04
	scriptend
script5a43:
	loadscript scriptHlp.script15_5731
script5a47:
	loadscript scriptHlp.script15_5758
script5a4b:
	loadscript scriptHlp.script15_577e
script5a4f:
	jumpifglobalflagset $40 stubScript
	disableinput
	wait 40
	showtext $2a1e
	wait 30
	setanimation $01
	setspeed SPEED_100
	setangle $08
	applyspeed $11
	setanimation $09
	writeinteractionbyte $7f $2d
	playsound $7b
script5a68:
	asm15 $56bd
	asm15 $56c2
	jumpifmemoryset $cddb $80 script5a76
	jump2byte script5a68
script5a76:
	setglobalflag $40
	asm15 $5671
	enableinput
	scriptend
script5a7d:
	checkpalettefadedone
	wait 70
	setspeed SPEED_100
	movenpcup $50
	checkmemoryeq $cbb5 $01
	movenpcup $10
	showtext $2a1f
	writememory $cbb5 $02
	checkmemoryeq $cbb5 $03
	movenpcdown $40
	writeinteractionbyte $4b $08
	writeinteractionbyte $4d $80
	checkmemoryeq $cbb5 $05
	checkpalettefadedone
	movenpcdown $70
	checkmemoryeq $cbb5 $07
	wait 20
	setspeed SPEED_200
	movenpcdown $18
	scriptend
script5aae:
	initcollisions
script5aaf:
	checkabutton
	disableinput
	wait 20
	writeinteractionbyte $79 $01
	asm15 $5ca8
	wait 6
	showtext $2a21
	wait 6
	writeinteractionbyte $79 $00
	setanimation $03
	enableinput
	jump2byte script5aaf
script5ac7:
	rungenericnpc $2a23
script5aca:
	rungenericnpclowindex $00
script5acc:
	rungenericnpclowindex $03
script5ace:
	rungenericnpclowindex $04
script5ad0:
	jumpifmemoryeq $cc01 $01 script5ad8
	rungenericnpclowindex $05
script5ad8:
	rungenericnpclowindex $08
script5ada:
	rungenericnpclowindex $09
script5adc:
	rungenericnpclowindex $07
script5ade:
	initcollisions
script5adf:
	checkabutton
	ormemory $cfde $08
	cplinkx $48
	setanimation $fe $48
	showtext $04f5
	setanimation $02
	jump2byte script5adf
script5af0:
	rungenericnpclowindex $00
script5af2:
	rungenericnpclowindex $01
script5af4:
	initcollisions
script5af5:
	enableinput
	checkabutton
	disableinput
script5af8:
	jumpifinteractionbyteeq $4f $00 script5b00
	wait 1
	jump2byte script5af8
script5b00:
	asm15 $5800
	showloadedtext
	jump2byte script5af5
script5b06:
	jumpifglobalflagset $14 script5b0c
	rungenericnpclowindex $07
script5b0c:
	rungenericnpclowindex $0c
script5b0e:
	initcollisions
script5b0f:
	checkabutton
	asm15 $5817
	showtextlowindex $15
	asm15 $5826
	jump2byte script5b0f
script5b1a:
	initcollisions
script5b1b:
	checkabutton
	asm15 $5817
	showtextlowindex $16
	asm15 $5826
	jump2byte script5b1b
script5b26:
	initcollisions
script5b27:
	checkabutton
	asm15 $5817
	showtextlowindex $19
	asm15 $5826
	jump2byte script5b27
script5b32:
	initcollisions
script5b33:
	checkabutton
	asm15 $5817
	showtextlowindex $1a
	asm15 $5826
	jump2byte script5b33
script5b3e:
	initcollisions
	settextid $1440
	jump2byte script5b4a
script5b44:
	setcollisionradii $06 $06
	settextid $1441
script5b4a:
	checkabutton
	asm15 $5ca8
	showloadedtext
	wait 10
	setanimation $02
	jump2byte script5b4a
script5b54:
	disableinput
	setspeed SPEED_100
	jumpifinteractionbyteeq $48 $00 script5b60
	movenpcleft $10
	jump2byte script5b62
script5b60:
	movenpcright $10
script5b62:
	asm15 $582c
	wait 10
	enableinput
	scriptend
script5b68:
	rungenericnpc $1420
script5b6b:
	rungenericnpc $1421
script5b6e:
	rungenericnpc $1422
script5b71:
	rungenericnpc $1423
script5b74:
	rungenericnpc $1424
script5b77:
	rungenericnpc $1425
script5b7a:
	rungenericnpc $1430
script5b7d:
	rungenericnpc $1431
script5b80:
	rungenericnpc $1434
script5b83:
	rungenericnpc $1435
script5b86:
	rungenericnpc $1400
script5b89:
	rungenericnpc $1401
script5b8c:
	rungenericnpc $1402
script5b8f:
	jumpifmemoryeq $cc01 $01 script5b98
	rungenericnpc $1403
script5b98:
	rungenericnpc $1408
script5b9b:
	rungenericnpc $1404
script5b9e:
	rungenericnpc $1405
script5ba1:
	rungenericnpc $1406
script5ba4:
	rungenericnpc $1407
script5ba7:
	rungenericnpc $1414
script5baa:
	rungenericnpc $1415
script5bad:
	rungenericnpc $1418
script5bb0:
	rungenericnpc $1417
script5bb3:
	initcollisions
script5bb4:
	wait 60
	setanimation $01
	wait 30
script5bb8:
	asm15 $5862 $01
	wait 30
	jump2byte script5bb4
script5bbf:
	scriptend
script5bc0:
	checkmemoryeq $cfd1 $02
	wait 10
	setspeed SPEED_180
	movenpcleft $2c
	asm15 $5834
	wait 30
	setanimation $0b
	setangle $08
	applyspeed $2c
	writeinteractionbyte $79 $01
	wait 90
	writeinteractionbyte $7b $01
	asm15 $5847
	jump2byte script5bb8
script5bdf:
	jumpifglobalflagset $41 stubScript
	setdisabledobjectsto11
	wait 100
	disableinput
	wait 40
	callscript script51ac
	wait 30
	showtext $1622
	wait 30
	setspeed SPEED_100
	movenpcdown $11
	movenpcright $11
	movenpcdown $09
	setspeed SPEED_080
	applyspeed $21
	setspeed SPEED_100
	applyspeed $39
	setglobalflag $41
	enableinput
	scriptend
script5c04:
	wait 90
	setspeed SPEED_100
	setanimation $00
	wait 30
	movenpcup $80
	scriptend
script5c0d:
	initcollisions
script5c0e:
	checkabutton
	turntofacelink
	showloadedtext
	setanimation $00
	jump2byte script5c0e
script5c15:
	rungenericnpc $1520
script5c18:
	rungenericnpc $1521
script5c1b:
	rungenericnpc $1522
script5c1e:
	rungenericnpc $1523
script5c21:
	rungenericnpc $1524
script5c24:
	rungenericnpc $1525
script5c27:
	rungenericnpc $1500
script5c2a:
	rungenericnpc $1501
script5c2d:
	rungenericnpc $1502
script5c30:
	rungenericnpc $1503
script5c33:
	rungenericnpc $1504
script5c36:
	rungenericnpc $1505
script5c39:
	rungenericnpc $1508
script5c3c:
	rungenericnpc $1507
script5c3f:
	rungenericnpc $1510
script5c42:
	rungenericnpc $1511
script5c45:
	rungenericnpc $1512
script5c48:
	rungenericnpc $1513
script5c4b:
	rungenericnpc $1515
script5c4e:
	rungenericnpc $1518
script5c51:
	initcollisions
script5c52:
	checkabutton
	asm15 $5ca8
	ormemory $cfde $04
	showtext $2510
	wait 10
	setanimation $00
	jump2byte script5c52
script5c62:
	setspeed SPEED_100
	movenpcleft $50
	wait 8
	movenpcright $50
	wait 8
	movenpcleft $30
	asm15 $5854 $3c
	wait 50
	writememory $cfd1 $01
	wait 90
	writememory $cfd1 $02
	setspeed SPEED_040
	applyspeed $40
	wait 30
	writememory $cfd1 $03
script5c84:
	scriptend
script5c85:
	rungenericnpc $2500
script5c88:
	rungenericnpc $2501
script5c8b:
	rungenericnpc $2502
script5c8e:
	rungenericnpc $2503
script5c91:
	rungenericnpc $2504
script5c94:
	rungenericnpc $2505
script5c97:
	checkmemoryeq $cfd1 $02
	writeinteractionbyte $79 $01
	wait 32
	showtext $2512
	wait 30
	setanimation $03
	wait 32
	showtext $2513
	wait 30
	setanimation $00
	wait 32
	showtext $2514
	wait 60
	writememory $cfd1 $03
script5cb8:
	writeinteractionbyte $79 $01
	writeinteractionbyte $78 $78
script5cbe:
	asm15 $585a
	addinteractionbyte $78 $ff
	jumpifinteractionbyteeq $78 $00 script5ccc
	wait 1
	jump2byte script5cbe
script5ccc:
	playsound $51
	writeinteractionbyte $79 $00
	setspeed SPEED_200
	movenpcright $38
	scriptend
script5cd6:
	wait 30
	showtext $2511
	wait 30
	writememory $cfd1 $01
	checkmemoryeq $cfd1 $03
	jump2byte script5cb8
script5ce5:
	wait 30
	setspeed SPEED_180
	movenpcleft $0a
script5cea:
	wait 3
	movenpcup $21
	wait 3
	movenpcright $20
	wait 3
	movenpcdown $36
	wait 3
	movenpcright $16
	wait 3
	movenpcup $16
	wait 3
	movenpcleft $35
	jump2byte script5cea
script5d04:
	wait 30
	jumpifinteractionbyteeq $78 $00 script5d13
	asm15 $5862 $02
	wait 90
	setanimation $03
	jump2byte script5d04
script5d13:
	writememory $cfd1 $01
	asm15 $5862 $03
	wait 90
	asm15 $5870 $00
	wait 20
	asm15 $5870 $01
	wait 20
	asm15 fadeoutToWhite
	checkpalettefadedone
	wait 10
	writememory $cfd1 $02
	setanimation $03
	asm15 fadeinFromWhite
	checkpalettefadedone
	wait 30
	asm15 $5854 $28
	wait 40
	addinteractionbyte $45 $01
	setspeed SPEED_180
	movenpcleft $21
	wait 30
	writememory $cfdf $ff
	scriptend
script5d48:
	loadscript scriptHlp.script15_58d3
script5d4c:
	checkmemoryeq $cfd1 $02
	setanimation $01
	wait 30
	showtext $251b
	wait 30
	writememory $cfd1 $03
	scriptend
script5d5c:
	initcollisions
script5d5d:
	checkabutton
	turntofacelink
	showloadedtext
	setanimation $00
	jump2byte script5d5d
script5d64:
	setspeed SPEED_200
	movenpcright $19
	wait 8
	setanimation $03
	writeinteractionbyte $79 $01
	wait 37
script5d70:
	setanimation $03
script5d72:
	wait 30
	asm15 $5862 $02
	wait 90
	jump2byte script5d70
script5d7a:
	rungenericnpc $251c
script5d7d:
	initcollisions
	jump2byte script5d72
script5d80:
	checkcfc0bit 0
	wait 60
	asm15 $5854 $1e
	checkcfc0bit 2
	setspeed SPEED_200
	setanimation $01
	setangle $0c
	applyspeed $31
	scriptend
script5d90:
	jumpifglobalflagset $11 script5d97
	rungenericnpc $3800
script5d97:
	rungenericnpc $3801
script5d9a:
	checkmemoryeq $cfd1 $03
	setspeed SPEED_280
	movenpcdown $0e
	wait 4
	movenpcleft $0d
	wait 16
	scriptend
script5da8:
	rungenericnpc $1809
script5dab:
	setspeed SPEED_180
	movenpcleft $16
	jump2byte script5cea
script5db1:
	loadscript scriptHlp.script15_5946
script5db5:
	setcoords $24 $78
	wait 30
	setangle $00
	setspeed SPEED_040
	applyspeed $45
	checkmemoryeq $cfd2 $ff
	wait 60
	setangle $10
	setspeed SPEED_080
	applyspeed $23
	wait 10
	writememory $cfd0 $1a
	scriptend
script5dd0:
	checkmemoryeq $cc93 $00
	wait 8
	showtext $1315
	wait 8
	applyspeed $0c
	xorcfc0bit 0
	scriptend
script5ddd:
	rungenericnpclowindex $10
script5ddf:
	rungenericnpclowindex $03
script5de1:
	wait 30
	showtextlowindex $11
	writememory $cfd1 $02
	checkmemoryeq $cfd1 $03
	jump2byte script5cb8
script5dee:
	jumpifglobalflagset $0b script5df5
	rungenericnpc $5900
script5df5:
	rungenericnpc $5901
script5df8:
	jumpifglobalflagset $0b script5dff
	rungenericnpc $5902
script5dff:
	rungenericnpc $5901
script5e02:
	loadscript scriptHlp.script15_5a6d
script5e06:
	jumpifinteractionbyteeq $4b $28 script5e1e
	checkmemoryeq $d00b $60
	setspeed SPEED_100
	jumpifinteractionbyteeq $4d $48 script5e1a
	setangle $08
	jump2byte script5e1c
script5e1a:
	setangle $18
script5e1c:
	applyspeed $10
script5e1e:
	scriptend
script5e1f:
	checkmemoryeq $cfd1 $02
	setanimation $01
	wait 30
	setspeed SPEED_100
	movenpcup $21
	wait 6
	movenpcright $11
	wait 6
	movenpcup $34
	wait 180
	movenpcdown $34
	wait 6
	movenpcleft $11
	wait 6
	movenpcdown $21
	wait 60
	showtext $1303
	wait 30
	movenpcdown $31
	wait 6
	setanimation $01
	asm15 scriptHlp.func_5155 $03
	wait 60
	setspeed SPEED_080
	setangle $08
	applyspeed $15
	wait 60
	setangle $18
	applyspeed $15
	wait 30
	giveitem $0302
	setdisabledobjectsto11
	wait 30
	asm15 scriptHlp.func_5155 $00
	setspeed SPEED_100
	movenpcup $31
	wait 6
	setanimation $02
	wait 30
	showtext $1304
	wait 30
	writememory $cfd1 $03
	checkmemoryeq $cfd1 $04
	playsound $fb
	wait 180
	showtext $1305
	wait 40
	movenpcdown $21
	wait 4
	movenpcright $11
	wait 4
	movenpcdown $11
	wait 60
	showtext $5907
	writememory $cfd1 $05
	scriptend
script5e8f:
	movenpcup $84
	scriptend
script5e92:
	setspeed SPEED_100
	movenpcup $10
	wait 60
	movenpcright $18
	wait 30
	setanimation $03
	wait 60
	showtext $5905
	wait 30
	showtext $1300
	wait 30
	movenpcleft $18
	wait 8
	setanimation $02
	wait 40
	writememory $c6bd $00
	asm15 $5a28
	wait 20
	setanimation $00
	wait 10
	movenpcup $24
	wait 40
	playsound $5e
	wait 20
	setspeed SPEED_080
	setangle $10
	applyspeed $48
	setanimation $03
	setangle $08
	applyspeed $30
	writememory $cfd1 $01
	checkmemoryeq $cfd1 $03
	setspeed SPEED_100
	movenpcleft $18
	setanimation $00
	wait 30
	showtext $5906
	wait 30
	setanimation $02
	wait 30
	showtext $590c
	wait 30
	writememory $cd00 $00
	asm15 $59f3 $01
	setdisabledobjectsto00
	movenpcdown $34
	writememory $cfd1 $04
	setglobalflag $0b
	scriptend
script5ef4:
	wait 60
	showtext $5908
	wait 30
	writememory $cbc3 $00
	asm15 $5a2f
	enableinput
	rungenericnpc $5909
script5f04:
	jumpifglobalflagset $0b script5f0b
	rungenericnpc $5903
script5f0b:
	rungenericnpc $5909
script5f0e:
	loadscript scriptHlp.script15_5aa2
script5f12:
	initcollisions
script5f13:
	checkabutton
	asm15 $5a37
	showloadedtext
	jump2byte script5f13
script5f1a:
	asm15 $5fb9
	asm15 $5a4d
	initcollisions
	jumptable_interactionbyte $7b
	.dw script5f2b
	.dw script5f2f
	.dw script5f64
	.dw script5f99
script5f2b:
	checkabutton
	showloadedtext
	jump2byte script5f2b
script5f2f:
	checkmemoryeq $cde0 $00
	asm15 objectUnmarkSolidPosition
script5f36:
	asm15 $5fc3 $02
	asm15 $5fd2 $60
	callscript script5fb8
	asm15 $5fc3 $03
	asm15 $5fd2 $60
	callscript script5fb8
	asm15 $5fc3 $00
	asm15 $5fd2 $60
	callscript script5fb8
	asm15 $5fc3 $01
	asm15 $5fd2 $60
	callscript script5fb8
	jump2byte script5f36
script5f64:
	checkmemoryeq $cde0 $00
	asm15 objectUnmarkSolidPosition
script5f6b:
	asm15 $5fc3 $02
	asm15 $5fd2 $80
	callscript script5fb8
	asm15 $5fc3 $01
	asm15 $5fd2 $20
	callscript script5fb8
	asm15 $5fc3 $00
	asm15 $5fd2 $80
	callscript script5fb8
	asm15 $5fc3 $03
	asm15 $5fd2 $20
	callscript script5fb8
	jump2byte script5f6b
script5f99:
	checkmemoryeq $cde0 $00
	asm15 objectUnmarkSolidPosition
script5fa0:
	asm15 $5fc3 $02
	asm15 $5fd2 $c0
	callscript script5fb8
	asm15 $5fc3 $00
	asm15 $5fd2 $c0
	callscript script5fb8
	jump2byte script5fa0
script5fb8:
	jumpifinteractionbyteeq $71 $01 script5fcd
	asm15 $5fdc
	jumpifmemoryset $cddb $80 script5fcb
	asm15 objectApplySpeed
	jump2byte script5fb8
script5fcb:
	wait 20
	retscript
script5fcd:
	disableinput
	writeinteractionbyte $71 $00
	asm15 $5ca8
	showloadedtext
	wait 30
	asm15 $5fd6
	enableinput
	jump2byte script5fb8
script5fdc:
	rungenericnpclowindex $06
script5fde:
	rungenericnpclowindex $00
script5fe0:
	rungenericnpclowindex $01
script5fe2:
	rungenericnpclowindex $02
script5fe4:
	rungenericnpclowindex $03
script5fe6:
	rungenericnpclowindex $04
script5fe8:
	rungenericnpclowindex $05
script5fea:
	jumpifglobalflagset $0b script5ff0
	rungenericnpclowindex $00
script5ff0:
	rungenericnpclowindex $01
script5ff2:
	jumpifglobalflagset $0b script5ff8
	rungenericnpclowindex $10
script5ff8:
	rungenericnpclowindex $11
script5ffa:
	rungenericnpclowindex $01
script5ffc:
	rungenericnpclowindex $02
script5ffe:
	rungenericnpclowindex $03
script6000:
	rungenericnpclowindex $04
script6002:
	rungenericnpclowindex $07
script6004:
	checkmemoryeq $cfd1 $02
	writeinteractionbyte $5c $06
	scriptend
script600c:
	writeinteractionbyte $5c $02
	rungenericnpclowindex $12
script6011:
	jumpifglobalflagset $0b script6018
	rungenericnpc $1620
script6018:
	rungenericnpc $1621
script601b:
	checkmemoryeq $cfd1 $04
	asm15 objectSetVisible82
	wait 240
	writememory $cfdf $ff
	callscript script51ac
	scriptend
script602b:
	rungenericnpc $1610
script602e:
	rungenericnpc $1611
script6031:
	rungenericnpc $1612
script6034:
	rungenericnpc $1613
script6037:
	rungenericnpc $1614
script603a:
	rungenericnpc $1615
script603d:
	rungenericnpc $1600
script6040:
	jumpifmemoryeq $cc01 $01 script6049
	rungenericnpc $1601
script6049:
	rungenericnpc $1608
script604c:
	rungenericnpc $1602
script604f:
	rungenericnpc $1604
script6052:
	rungenericnpc $1605
script6055:
	rungenericnpc $1609
script6058:
	jumpifmemoryeq $cc01 $01 script6061
	rungenericnpc $1607
script6061:
	rungenericnpc $160a
script6064:
	rungenericnpclowindex $0a
script6066:
	rungenericnpclowindex $00
script6068:
	rungenericnpclowindex $01
script606a:
	rungenericnpclowindex $02
script606c:
	rungenericnpclowindex $03
script606e:
	wait 240
	setanimation $00
script6071:
	setangle $10
	setspeed SPEED_200
	applyspeed $10
	wait 30
	setangle $08
	setspeed SPEED_080
	applyspeed $20
	writeinteractionbyte $79 $01
	wait 60
	writeinteractionbyte $79 $00
	applyspeed $20
	writeinteractionbyte $79 $01
	wait 60
	scriptend
script608c:
	disablemenu
	wait 240
	asm15 $5b23
	setanimation $00
	playsound $a6
	writememory $cfd1 $01
	jump2byte script6071
script609b:
	loadscript scriptHlp.script15_5c66
script609f:
	jumptable_interactionbyte $7c
	.dw script60a7
	.dw script60ba
	.dw script60bc
script60a7:
	initcollisions
	checkabutton
	disableinput
	showloadedtext
	wait 30
	setanimation $02
	writeinteractionbyte $7b $01
	asm15 $5b4b
	wait 30
	showtextlowindex $0c
	orroomflag $40
	enableinput
script60ba:
	rungenericnpclowindex $0c
script60bc:
	rungenericnpclowindex $0d
script60be:
	checkmemoryeq $d00b $50
	disableinput
	wait 30
	showtextlowindex $0e
	setspeed SPEED_180
	movenpcup $11
	wait 30
	setanimation $02
	wait 30
	setzspeed -$01c0
	playsound $53
script60d3:
	asm15 objectUpdateSpeedZ $20
	jumpifinteractionbyteeq $4f $00 script60df
	wait 1
	jump2byte script60d3
script60df:
	wait 20
	showtextlowindex $0f
	wait 30
	movenpcup $39
	wait 6
	movenpcleft $2b
	enableinput
	orroomflag $80
	scriptend
script60ed:
	initcollisions
	jumpifroomflagset $40 script6151
script60f2:
	jumpifitemobtained $16 script60fb
script60f6:
	checkabutton
	showtextlowindex $1c
	jump2byte script60f6
script60fb:
	asm15 $5ad8
	checkabutton
	showtextlowindex $10
	disableinput
	wait 10
	asm15 $5b0a $06
	writeinteractionbyte $60 $7f
	playsound $5e
	wait 40
	settextid $0a13
	jumpifmemoryeq $c6ea $00 script6119
	settextid $0a11
script6119:
	showloadedtext
	jumpiftextoptioneq $00 script612b
	settextid $0a1a
script6121:
	wait 20
	setanimation $02
	writeinteractionbyte $7b $01
	showloadedtext
	enableinput
	jump2byte script60fb
script612b:
	jumpifinteractionbyteeq $7d $00 script6135
script6130:
	settextid $0a1b
	jump2byte script6121
script6135:
	asm15 removeRupeeValue $04
	wait 20
	setanimation $02
	writeinteractionbyte $7b $01
	showtextlowindex $14
	jumpiftextoptioneq $00 script614c
script6145:
	wait 20
	showtextlowindex $26
	jumpiftextoptioneq $01 script6145
script614c:
	wait 20
	showtextlowindex $15
	wait 20
	scriptend
script6151:
	asm15 $5acc
	disableinput
	jumpifmemoryeq $cfde $ff script6162
	wait 30
	asm15 $5b7e
	wait 30
	jump2byte script6176
script6162:
	asm15 $5aed
	showtextlowindex $19
	jumpiftextoptioneq $01 script6176
	jumpifinteractionbyteeq $7d $01 script6130
	asm15 removeRupeeValue $04
	jump2byte script614c
script6176:
	enableinput
	jump2byte script60f2
script6179:
	makeabuttonsensitive
script617a:
	checkabutton
	asm15 $5bc5
	jumpifinteractionbyteeq $7f $00 script6187
	showtextlowindex $37
	jump2byte script617a
script6187:
	showtextlowindex $38
	jump2byte script617a
script618b:
	disableinput
	jumpifmemoryset $c647 $01 script619a
	setangleandanimation $10
	showtextlowindex $1d
	ormemory $d13e $01
script619a:
	makeabuttonsensitive
script619b:
	setangleandanimation $08
	enableinput
	checkabutton
	disableinput
	asm15 $5bee
	showtextlowindex $1f
	asm15 $5bd1
	jumpifinteractionbyteeq $7f $00 script619b
	showtextlowindex $20
	jumptable_memoryaddress wSelectedTextOption
	.dw script61ba
	.dw script61b6
script61b6:
	showtextlowindex $22
	jump2byte script619b
script61ba:
	showtextlowindex $23
	asm15 $5bdf
	ormemory $d13e $04
	spawninteraction $8f00 $48 $18
	spawninteraction $8f00 $58 $38
	wait 30
	showtextlowindex $24
	wait 60
	showtextlowindex $25
	ormemory $d13e $08
	movenpcleft $10
	enablemenu
	scriptend
script61db:
	jumpifmemoryset $c647 $01 script61f4
	jumpifmemoryset $d13e $01 script61e9
	jump2byte script61db
script61e9:
	disableinput
	wait 30
	setangleandanimation $10
	showtextlowindex $1e
	ormemory $d13e $02
	enableinput
script61f4:
	makeabuttonsensitive
script61f5:
	setangleandanimation $00
script61f7:
	jumpifinteractionbyteeq $71 $00 script6206
	asm15 $5bee
	showtextlowindex $1e
	writeinteractionbyte $71 $00
	jump2byte script61f5
script6206:
	jumpifmemoryset $d13e $04 script620e
	jump2byte script61f7
script620e:
	setangleandanimation $10
script6210:
	jumpifmemoryset $d13e $08 script6219
	wait 1
	jump2byte script6210
script6219:
	movenpcleft $20
	ormemory $c647 $02
	setdisabledobjectsto00
	scriptend
script6221:
	makeabuttonsensitive
script6222:
	setangleandanimation $10
	checkabutton
	asm15 $5bee
	jumpifroomflagset $80 script6257
	jumpifitemobtained $4d script6234
	showtextlowindex $40
	jump2byte script6222
script6234:
	disableinput
	showtextlowindex $40
	wait 30
	showtextlowindex $41
	asm15 $5bfe
	setspeed SPEED_100
	applyspeed $10
	asm15 $5bfe
	asm15 $5c06
	spawninteraction $8004 $38 $48
	playsound $5e
	wait 120
	asm15 $5bee
	showtextlowindex $42
	enableinput
	jump2byte script6222
script6257:
	jumpifitemobtained $21 script625f
	showtextlowindex $43
	jump2byte script6222
script625f:
	showtextlowindex $44
	jump2byte script6222
script6263:
	jumpifglobalflagset $14 script6269
	rungenericnpclowindex $67
script6269:
	initcollisions
	jumpifroomflagset $40 script62bf
	jumpifglobalflagset $73 script62da
	jumpifglobalflagset $69 script6299
script6276:
	checkabutton
	disableinput
	showtextlowindex $45
	wait 20
	jumpiftextoptioneq $00 script6285
	wait 30
	showtextlowindex $46
	enableinput
	jump2byte script6276
script6285:
	askforsecret $05
	wait 20
	jumpifmemoryeq $cc89 $00 script6293
	showtextlowindex $48
	enableinput
	jump2byte script6276
script6293:
	setglobalflag $69
	showtextlowindex $47
	jump2byte script629d
script6299:
	checkabutton
	disableinput
	showtextlowindex $51
script629d:
	wait 2
	jumpiftextoptioneq $00 script62a9
	wait 20
	showtextlowindex $52
	enableinput
	jump2byte script6299
script62a9:
	wait 20
	showtextlowindex $4a
	wait 2
	jumpiftextoptioneq $00 script62ba
script62b2:
	wait 20
	showtextlowindex $4b
	wait 20
	jumpiftextoptioneq $01 script62b2
script62ba:
	wait 20
	showtextlowindex $4c
	wait 40
	scriptend
script62bf:
	asm15 $5acc
	disableinput
	jumpifmemoryeq $cfde $ff script62e1
	showtextlowindex $4f
	wait 30
	asm15 $5c13
	giveitem $6100
	wait 30
	setglobalflag $73
	generatesecret $05
	showtextlowindex $50
	enableinput
script62da:
	checkabutton
	generatesecret $05
	showtextlowindex $53
	jump2byte script62da
script62e1:
	showtextlowindex $4d
	wait 20
	jumpiftextoptioneq $00 script62ba
	showtextlowindex $4e
	enableinput
	jump2byte script6299
script62ed:
	loadscript scriptHlp.script15_5c26
script62f1:
	loadscript scriptHlp.script15_5c40
script62f5:
	makeabuttonsensitive
script62f6:
	checkabutton
	showtext $1108
	jump2byte script62f6
script62fc:
	makeabuttonsensitive
script62fd:
	checkabutton
	showtext $1109
	jump2byte script62fd
script6303:
	setcollisionradii $04 $04
	makeabuttonsensitive
script6307:
	checkabutton
	showloadedtext
	jump2byte script6307
script630b:
	setcollisionradii $04 $04
	makeabuttonsensitive
script630f:
	checkabutton
	disableinput
	jumpifglobalflagset $6f script6343
	showtext $1148
	wait 30
	jumpiftextoptioneq $00 script6322
	showtext $1149
	jump2byte script6348
script6322:
	askforsecret $01
	wait 30
	jumpifmemoryeq $cc89 $00 script6330
	showtext $114b
	jump2byte script6348
script6330:
	setglobalflag $65
	showtext $114a
	wait 30
	giveitem $2a02
	wait 30
	generatesecret $01
	setglobalflag $6f
	showtext $114c
	jump2byte script6348
script6343:
	generatesecret $01
	showtext $114d
script6348:
	enableinput
	jump2byte script630f
script634b:
	initcollisions
script634c:
	checkabutton
	asm15 $5ca8
	ormemory $cfde $02
	showtext $5705
	wait 10
	setanimation $00
	jump2byte script634c
script635c:
	wait 30
	setanimation $02
	wait 90
	setanimation $03
	scriptend
script6363:
	rungenericnpc $5717
script6366:
	rungenericnpc $5718
script6369:
	initcollisions
script636a:
	checkabutton
	setdisabledobjectsto11
	asm15 interactionSetEnabledBit7
	writeinteractionbyte $77 $01
	cplinkx $48
	addinteractionbyte $48 $02
	setanimation $fe $48
	ormemory $cfde $01
	showtext $3214
	writeinteractionbyte $77 $00
	writeinteractionbyte $4f $00
	wait 10
	setdisabledobjectsto00
	setanimation $01
	asm15 interactionUnsetEnabledBit7
	jump2byte script636a
script6390:
	initcollisions
	jumpifglobalflagset $3c script639f
script6395:
	checkabutton
	setanimation $02
	showtext $3216
	setanimation $00
	jump2byte script6395
script639f:
	checkmemoryeq $cfd0 $05
	setanimation $02
	wait 30
	showtext $3217
	setanimation $00
	writememory $cfd0 $06
	checkmemoryeq $cfd0 $07
	setanimation $02
	setspeed SPEED_100
	setangle $18
	applyspeed $10
	setangle $00
	applyspeed $60
	scriptend
script63c0:
	checkmemoryeq $cfd1 $01
	wait 30
	showtext $1301
	wait 30
	setanimation $03
	wait 20
	showtext $1302
	writememory $cfd1 $02
	wait 10
	setanimation $02
	checkmemoryeq $cfd1 $06
	wait 150
	setspeed SPEED_080
	movenpcup $60
	writememory $cfd1 $07
	scriptend
script63e5:
	checkmemoryeq $cfd0 $07
	playsound $f0
	showtext $130e
	playsound $4a
	wait 10
	writememory $cfd0 $08
	checkmemoryeq $cfd0 $09
	showtext $130f
	wait 60
	writememory $cfd0 $0a
	scriptend
script6402:
	checkmemoryeq $cfd0 $0c
	showtext $1310
	wait 30
	writememory $cfd0 $0d
	checkinteractionbyteeq $7e $01
	wait 10
	showtext $1311
	wait 120
	writememory $cfd0 $0f
	scriptend
script641b:
	wait 180
	asm15 fadeoutToWhite
	checkpalettefadedone
	writememory $cfc0 $01
	wait 30
	asm15 fadeinFromWhite
	setspeed SPEED_040
	setangle $10
	checkmemoryeq $cfc0 $04
	scriptend
script6431:
	wait 60
	setspeed SPEED_080
	movenpcdown $64
	setspeed SPEED_040
	movenpcdown $40
	setspeed SPEED_080
	movenpcdown $2c
	wait 60
	setanimation $0a
	showtext $130b
	wait 20
	writememory $cfc0 $01
	checkmemoryeq $cfc0 $02
	wait 30
	showtext $130c
	writememory wCutsceneTrigger $10
	scriptend
script6456:
	setanimation $0a
	checkpalettefadedone
	wait 60
	showtext $130d
	wait 6
	orroomflag $40
	scriptend
script6462:
	setspeed SPEED_080
	setangle $10
	checkcfc0bit 0
	wait 8
	applyspeed $11
	wait 20
	applyspeed $11
	wait 20
	applyspeed $11
	checkcfc0bit 2
	writeinteractionbyte $7f $2d
	playsound $fb
	playsound $8d
script6478:
	asm15 $5cb1
	asm15 $5cb6
	jumpifmemoryset $cddb $80 script6486
	jump2byte script6478
script6486:
	playsound $6b
script6488:
	asm15 $5cbd
	jumpifmemoryset $cddb $10 script6496
	asm15 $5cb1
	jump2byte script6488
script6496:
	xorcfc0bit 3
	scriptend
script6498:
	disableinput
	checkcfc0bit 0
	spawnenemyhere $6101
	wait 1
	enableinput
	scriptend
script64a0:
	showtext $1318
	wait 16
	showtext $1319
	writememory $cc4f $09
	setspeed SPEED_180
	movenpcdown $3c
	spawninteraction $3e02 $00 $28
	scriptend
script64b6:
	checkpalettefadedone
	wait 60
	showtext $1316
	wait 60
	asm15 fadeoutToWhite
	checkpalettefadedone
	scriptend
script64c1:
	rungenericnpc $131a
script64c4:
	rungenericnpclowindex $05
script64c6:
	rungenericnpclowindex $07
script64c8:
	asm15 $5180
	jumpifmemoryset $cddb $80 stubScript
	rungenericnpclowindex $14
script64d3:
	asm15 $5180
	jumpifmemoryset $cddb $80 stubScript
	writeinteractionbyte $5c $02
	rungenericnpclowindex $15
script64e1:
	initcollisions
script64e2:
	checkabutton
	turntofacelink
	writeinteractionbyte $48 $ff
	showloadedtext
	setanimation $00
	jump2byte script64e2
script64ec:
	loadscript scriptHlp.script15_5cc8
script64f0:
	loadscript scriptHlp.script15_5d50
script64f4:
	loadscript scriptHlp.script15_5d9b
script64f8:
	loadscript scriptHlp.script15_5dc5
script64fc:
	makeabuttonsensitive
script64fd:
	checkabutton
	turntofacelink
	showloadedtext
	asm15 $5d4a
	jump2byte script64fd
script6505:
	loadscript scriptHlp.script15_5df4
script6509:
	asm15 $5eb5
script650c:
	asm15 $5ee0
	jumpifmemoryset $cddb $80 script651d
	asm15 $5ed4
	asm15 $5e94
	jump2byte script650c
script651d:
	asm15 $5ec5
	asm15 $5eaa
	wait 180
	asm15 $5eaa
	jump2byte script6509
script6529:
	loadscript scriptHlp.script15_5ee7
script652d:
	initcollisions
script652e:
	asm15 interactionSetAnimation $02
	checkabutton
	asm15 interactionSetAnimation $03
	showtextlowindex $00
	jump2byte script652e
script653b:
	setanimation $05
	addinteractionbyte $60 $08
	setspeed SPEED_080
script6542:
	setanimation $06
	setangle $10
	applyspeed $10
	wait 8
	asm15 $5f15
	setanimation $05
	setanimation $06
	setangle $00
	applyspeed $10
	wait 8
	asm15 $5f15
	setanimation $05
	jump2byte script6542
script655c:
	setanimation $04
	addinteractionbyte $60 $08
	setspeed SPEED_080
script6563:
	setanimation $06
	setangle $00
	applyspeed $10
	wait 8
	asm15 $5f15
	setanimation $04
	setanimation $06
	setangle $10
	applyspeed $10
	wait 8
	asm15 $5f15
	setanimation $04
	jump2byte script6563
script657d:
	loadscript scriptHlp.script15_5f4f
script6581:
	writeinteractionbyte $7f $01
	checkpalettefadedone
	wait 60
	writememory $cfc0 $07
	wait 90
	writeinteractionbyte $7f $00
	setangle $18
	applyspeed $40
	wait 120
	writememory $cfdf $ff
	scriptend
script6598:
	setcoords $55 $62
	setanimation $07
	asm15 objectSetVisible83
	wait 60
	setspeed SPEED_040
	setangle $00
	applyspeed $14
	wait 10
	setangle $18
	applyspeed $30
	writeinteractionbyte $7f $01
	checkmemoryeq $cfc0 $04
	setangle $10
	scriptend
script65b6:
	writeinteractionbyte $7f $01
	checkpalettefadedone
	wait 150
	writeinteractionbyte $7f $00
	setangle $18
	applyspeed $60
	scriptend
script65c4:
	asm15 $5f22
	initcollisions
script65c8:
	checkabutton
	asm15 $5f35
	showloadedtext
	jump2byte script65c8
script65cf:
	initcollisions
script65d0:
	checkabutton
	disableinput
	asm15 $5ca8
	jumptable_interactionbyte $43
	.dw script65db
	.dw script65ea
script65db:
	jumpifroomflagset $20 script65e6
	showtextlowindex $01
	wait 30
	giveitem $1500
	wait 30
script65e6:
	showtextlowindex $02
	jump2byte script65ec
script65ea:
	showtextlowindex $00
script65ec:
	setanimation $04
	enableinput
	jump2byte script65d0
script65f1:
	jumptable_interactionbyte $43
	.dw script65f7
	.dw script6603
script65f7:
	asm15 $6001
	jumpifmemoryset $cddb $80 script6601
	scriptend
script6601:
	rungenericnpclowindex $07
script6603:
	asm15 $6007
	jumpifmemoryset $cddb $80 script660d
	scriptend
script660d:
	rungenericnpclowindex $08
script660f:
	loadscript scriptHlp.script15_600f
script6613:
	loadscript scriptHlp.script15_604e
script6617:
	jumpifinteractionbyteeq $71 $01 script662c
	asm15 $5fdc
	jumpifmemoryset $cddb $80 script662a
	asm15 objectApplySpeed
	jump2byte script6617
script662a:
	wait 20
	retscript
script662c:
	disableinput
	writeinteractionbyte $71 $00
	asm15 $5ca8
	showloadedtext
	wait 30
	asm15 $5fd6
	enableinput
	jump2byte script6617
script663b:
	loadscript scriptHlp.script15_6147
script663f:
	loadscript scriptHlp.script15_618c
script6643:
	asm15 objectSetInvisible
	initcollisions
script6647:
	writeinteractionbyte $71 $00
script664a:
	wait 1
	asm15 $61b9
	jumpifmemoryset $cddb $10 script664a
	callscript script66be
script6657:
	jumpifinteractionbyteeq $71 $01 script6679
	asm15 $61b9
	jumpifmemoryset $cddb $10 script6667
	jump2byte script6657
script6667:
	callscript script66cf
	jump2byte script6647
script666c:
	asm15 $61b9
	jumpifmemoryset $cddb $10 script6677
	jump2byte script666c
script6677:
	jump2byte script6647
script6679:
	disableinput
	writeinteractionbyte $71 $00
	jumpifroomflagset $20 script66b5
	showtextlowindex $07
	jumpiftradeitemeq $02 script668d
	callscript script66ce
	enableinput
	jump2byte script666c
script668d:
	wait 30
	showtextlowindex $08
	wait 30
	jumpiftextoptioneq $00 script669d
	showtextlowindex $0a
	callscript script66ce
	enableinput
	jump2byte script666c
script669d:
	showtextlowindex $09
	callscript script66ce
	wait 30
	showtextlowindex $0b
	callscript script66bd
	wait 30
	showtextlowindex $0c
	wait 30
	giveitem $4102
	callscript script66ce
	enableinput
	jump2byte script666c
script66b5:
	showtextlowindex $09
	callscript script66ce
	enableinput
	jump2byte script666c
script66bd:
	wait 30
script66be:
	writeinteractionbyte $71 $00
	asm15 objectSetVisible
	asm15 $61ec
	checkinteractionbyteeq $61 $ff
	asm15 $61e8
	retscript
script66ce:
	wait 30
script66cf:
	asm15 $61e4
script66d2:
	checkinteractionbyteeq $61 $ff
	asm15 objectSetInvisible
	retscript
script66d9:
	asm15 $61f4
	jumpifmemoryset $cddb $07 script66e5
	wait 90
	jump2byte script66ed
script66e5:
	asm15 $61de
	callscript script66d2
	wait 45
script66ed:
	jumptable_interactionbyte $78
	.dw script6702
	.dw script66ff
	.dw script670e
	.dw script6711
	.dw script6714
	.dw script6717
	.dw script671a
	.dw script671d
script66ff:
	showtextlowindex $26
	wait 30
script6702:
	asm15 setScreenShakeCounter $3c
	asm15 $c98 $6f
	wait 60
	showtextlowindex $25
	scriptend
script670e:
	showtextlowindex $27
	scriptend
script6711:
	showtextlowindex $28
	scriptend
script6714:
	showtextlowindex $29
	scriptend
script6717:
	showtextlowindex $2a
	scriptend
script671a:
	showtextlowindex $2b
	scriptend
script671d:
	showtextlowindex $0a
	scriptend
script6720:
	loadscript scriptHlp.script15_61fb
script6724:
	initcollisions
	jumpifroomflagset $80 script674d
script6729:
	checkabutton
	ormemory $cfde $10
	jumpifmemoryeq $cfde $1f script6739
	showtext $5702
	jump2byte script6729
script6739:
	setdisabledobjectsto11
	setanimation $01
	wait 20
	setangle $00
	setspeed SPEED_080
	applyspeed $20
	wait 20
	setanimation $00
	wait 30
	orroomflag $80
	setdisabledobjectsto00
script674a:
	showtext $5703
script674d:
	checkabutton
	jump2byte script674a
script6750:
	wait 120
	showtext $5706
	wait 30
	writememory wCutsceneTrigger $06
	scriptend
script675a:
	initcollisions
script675b:
	checkabutton
	showloadedtext
	jump2byte script675b
script675f:
	spawninteraction $470b $28 $44
	spawninteraction $4707 $28 $4c
	spawninteraction $4708 $28 $74
	scriptend
script676f:
	showtext $0d00
	scriptend
script6773:
	showtext $0d0b
	scriptend
script6777:
	jumptable_interactionbyte $77
	.dw script6783
	.dw script6788
	.dw script6783
	.dw script6788
	.dw script678d
script6783:
	showtextnonexitable $0d01
	jump2byte script6790
script6788:
	showtextnonexitable $0d05
	jump2byte script6790
script678d:
	showtextnonexitable $0d0a
script6790:
	jumpiftextoptioneq $00 script67a0
	writeinteractionbyte $7a $ff
	writememory $cbad $03
	writememory $cba0 $01
	scriptend
script67a0:
	jumpifmemoryeq $ccd5 $00 script67b2
	writeinteractionbyte $7a $ff
	writememory $cbad $01
	writememory $cba0 $01
	scriptend
script67b2:
	jumptable_interactionbyte $78
	.dw script67b8
	.dw script48ac
script67b8:
	writeinteractionbyte $7a $01
	writememory $cbad $00
	writememory $cba0 $01
	scriptend
script67c4:
	loadscript scriptHlp.script15_62a0
script67c8:
	setcollisionradii $0a $0c
	makeabuttonsensitive
script67cc:
	checkabutton
	disableinput
	asm15 $6320
	jumpifmemoryset $cddb $80 script67df
	jumpifitemobtained $44 script67ee
	jumpifitemobtained $59 script67f9
script67df:
	jumpifitemobtained $5b script67ee
	asm15 $6398 $00
	wait 30
	jumpiftextoptioneq $00 script6809
	jump2byte script6801
script67ee:
	asm15 $6398 $01
	wait 30
	jumpiftextoptioneq $00 script6809
	jump2byte script6801
script67f9:
	showtext $2419
	wait 30
	jumpiftextoptioneq $00 script6809
script6801:
	asm15 $6398 $03
	wait 1
	enableinput
	jump2byte script67cc
script6809:
	callscript script68d8
	jumpifmemoryset $cddb $80 script681a
script6812:
	asm15 $6398 $09
	enableinput
	checkabutton
	jump2byte script6812
script681a:
	disableinput
	callscript script68eb
	asm15 $6398 $02
	wait 30
	jumpiftextoptioneq $00 script6848
script6827:
	asm15 $6398 $04
	wait 30
	playsound $cd
	setanimation $03
	wait 30
	asm15 $6398 $05
	wait 30
	playsound $c8
	setanimation $06
	wait 30
	asm15 $6398 $06
	wait 30
	setanimation $02
	jumpiftextoptioneq $00 script6848
	jump2byte script6827
script6848:
	asm15 $6320
	jumpifmemoryset $cddb $80 script6859
	jumpifitemobtained $44 script6872
	jumpifitemobtained $59 script685d
script6859:
	jumpifitemobtained $5b script6872
script685d:
	asm15 $6320
	jumpifmemoryset $cddb $80 script686c
	writememory $cfdd $02
	jump2byte script687b
script686c:
	writememory $cfdd $03
	jump2byte script687b
script6872:
	asm15 $6398 $0b
	wait 30
	callscript script6899
	wait 30
script687b:
	asm15 $6398 $07
	wait 40
	asm15 fadeoutToWhite
	checkpalettefadedone
	asm15 clearAllItemsAndPutLinkOnGround
	asm15 $6331
	wait 40
	asm15 fadeinFromWhite
	checkpalettefadedone
	asm15 restartSound
	wait 40
	asm15 $6398 $08
	wait 40
	scriptend
script6899:
	asm15 $6320
	jumpifmemoryset $cddb $80 script68ab
	jumptable_memoryaddress wSelectedTextOption
	.dw script68b4
	.dw script68bd
	.dw script68c6
script68ab:
	jumptable_memoryaddress wSelectedTextOption
	.dw script68bd
	.dw script68c6
	.dw script68cf
script68b4:
	writememory $cfdd $00
	asm15 $6398 $0c
	retscript
script68bd:
	writememory $cfdd $01
	asm15 $6398 $0d
	retscript
script68c6:
	writememory $cfdd $02
	asm15 $6398 $0e
	retscript
script68cf:
	writememory $cfdd $03
	asm15 $6398 $0f
	retscript
script68d8:
	asm15 $6320
	jumpifmemoryset $cddb $80 script68e6
	asm15 scriptHlp.shootingGallery_checkLinkHasRupees $05
	retscript
script68e6:
	asm15 scriptHlp.shootingGallery_checkLinkHasRupees $04
	retscript
script68eb:
	asm15 $6320
	jumpifmemoryset $cddb $80 script68f9
	asm15 removeRupeeValue $05
	retscript
script68f9:
	asm15 removeRupeeValue $04
	retscript
script68fe:
	callscript script6959
	wait 30
	jumptable_memoryaddress $cfdb
	.dw script690d
	.dw script690d
	.dw script6913
	.dw script6919
script690d:
	asm15 $6398 $16
	wait 30
	scriptend
script6913:
	asm15 $6398 $17
	wait 30
	scriptend
script6919:
	setmusic $ff
	asm15 $6398 $18
	wait 30
	asm15 $6398 $15
	wait 30
	jumpiftextoptioneq $00 script6934
	asm15 $6398 $03
	wait 1
	asm15 $62ef
	enableinput
	jump2byte script67cc
script6934:
	callscript script68d8
	jumpifmemoryset $cddb $80 script6946
script693d:
	asm15 $6398 $09
	wait 1
	enableinput
	checkabutton
	jump2byte script693d
script6946:
	asm15 restartSound
	callscript script68eb
	asm15 $6398 $07
	wait 30
	asm15 $6398 $08
	asm15 $630a
	scriptend
script6959:
	jumptable_memoryaddress $cfd1
	.dw script6962
	.dw script6966
	.dw script696a
script6962:
	showtext $313f
	retscript
script6966:
	showtext $3140
	retscript
script696a:
	showtext $3141
	retscript
script696e:
	wait 30
	setmusic $ff
	asm15 $6320
	jumpifmemoryset $cddb $80 script6982
	jumpifitemobtained $44 script69ac
	jumpifitemobtained $59 script699a
script6982:
	jumpifitemobtained $5b script69ac
	asm15 $6398 $10
	wait 30
	giveitem $5b00
	wait 30
	asm15 $6398 $11
	wait 30
	asm15 $62ef
	enableinput
	jump2byte script67cc
script699a:
	showtext $241a
	wait 30
	giveitem $4400
	wait 30
	showtext $241b
	wait 30
	asm15 $62ef
	enableinput
	jump2byte script67cc
script69ac:
	asm15 $635b
	jumpifmemoryset $cddb $80 script69c0
	asm15 $6398 $13
	wait 1
	callscript script69d4
	wait 30
	jump2byte script69c9
script69c0:
	asm15 $6398 $12
	wait 1
	callscript script69f3
	wait 30
script69c9:
	asm15 $6398 $14
	wait 30
	asm15 $62ef
	enableinput
	jump2byte script67cc
script69d4:
	jumptable_memoryaddress $cfdd
	.dw script69df
	.dw script69df
	.dw script69e3
	.dw script69eb
script69df:
	giveitem $3400
	retscript
script69e3:
	asm15 $511f $0b
	showtext $0006
	retscript
script69eb:
	asm15 $511f $07
	showtext $0005
	retscript
script69f3:
	jumptable_memoryaddress $cfdd
	.dw script69fe
	.dw script69fe
	.dw script6a02
	.dw script6a06
script69fe:
	asm15 $6370
	retscript
script6a02:
	giveitem $3400
	retscript
script6a06:
	asm15 $511f $0c
	showtext $0007
	retscript
script6a0e:
	initcollisions
script6a0f:
	checkabutton
	callscript script6a15
	jump2byte script6a0f
script6a15:
	jumptable_interactionbyte $43
	.dw script6a25
	.dw script6a2a
	.dw script6a2f
	.dw script6a34
	.dw script6a39
	.dw script6a3e
	.dw script6a43
script6a25:
	asm15 $63ab $40
	retscript
script6a2a:
	asm15 $63ab $41
	retscript
script6a2f:
	asm15 $63ab $42
	retscript
script6a34:
	asm15 $63ab $43
	retscript
script6a39:
	asm15 $63ab $44
	retscript
script6a3e:
	asm15 $63ab $45
	retscript
script6a43:
	asm15 $63ab $46
	retscript
script6a48:
	disableinput
	setcoords $58 $a8
	playsound $6f
	asm15 setScreenShakeCounter $06
	wait 20
	asm15 setScreenShakeCounter $06
	wait 20
	asm15 setScreenShakeCounter $06
	wait 60
	setspeed SPEED_200
	movenpcleft $11
	setanimation $00
	wait 30
	showtext $2470
	wait 30
	showtext $2471
	wait 30
	movenpcright $11
	enableinput
	scriptend
script6a70:
	asm15 $6269 $04
	jumpifmemoryset $cddb $80 stubScript
script6a7a:
	asm15 $6523
	initcollisions
script6a7e:
	jumpifinteractionbyteeq $71 $01 script6a96
	asm15 $65bd
	jumpifmemoryset $cddb $80 script6a91
	asm15 objectApplySpeed
	jump2byte script6a7e
script6a91:
	asm15 $653f
	jump2byte script6a7e
script6a96:
	jumpifinteractionbyteeq $42 $0d script70b0
	disableinput
	writeinteractionbyte $71 $00
	asm15 $5ca8
	asm15 $63e3
	wait 30
	asm15 $6556
	enableinput
	jump2byte script6a7e
script6aac:
	asm15 $6269 $04
	jumpifmemoryset $cddb $80 stubScript
	jump2byte script6ac2
script6ab8:
	asm15 $6271 $04
	jumpifmemoryset $cddb $80 stubScript
script6ac2:
	initcollisions
script6ac3:
	asm15 $64f6
	jumpifmemoryset $cddb $10 script6ace
	jump2byte script6ae0
script6ace:
	asm15 $651b $04
script6ad2:
	asm15 $64f6
	jumpifmemoryset $cddb $10 script6add
	jump2byte script6ae0
script6add:
	wait 1
	jump2byte script6ad2
script6ae0:
	asm15 $6509
script6ae3:
	jumpifinteractionbyteeq $71 $01 script6af5
	asm15 $64f6
	jumpifmemoryset $cddb $10 script6af3
	jump2byte script6ae3
script6af3:
	jump2byte script6ace
script6af5:
	jumpifinteractionbyteeq $42 $07 script6d1b
	jumpifinteractionbyteeq $42 $08 script6d71
	jumpifinteractionbyteeq $42 $0a script6eb0
	jumpifinteractionbyteeq $42 $0b script6f0d
	jumpifinteractionbyteeq $42 $0e script70c9
	disableinput
	writeinteractionbyte $71 $00
	asm15 $63f5
	wait 1
	enableinput
	jump2byte script6ae3
script6b19:
	asm15 $6269 $04
	jumpifmemoryset $cddb $80 stubScript
	initcollisions
	jumpifglobalflagset $2f script6b5f
script6b28:
	asm15 $651b $08
script6b2c:
	jumpifinteractionbyteeq $61 $01 script6b44
	jumpifinteractionbyteeq $61 $02 script6b49
script6b36:
	jumpifmemoryeq $cfdd $01 script6b72
	jumpifinteractionbyteeq $71 $01 script6b4e
	wait 1
	jump2byte script6b2c
script6b44:
	asm15 $661a
	jump2byte script6b36
script6b49:
	asm15 $661f
	jump2byte script6b36
script6b4e:
	disableinput
	asm15 $6509
	writeinteractionbyte $71 $00
	showtext $247b
	wait 30
	enableinput
	jump2byte script6b28
script6b5c:
	asm15 $6509
script6b5f:
	asm15 $6271 $04
	jumpifmemoryset $cddb $80 script6b6c
	setcoords $88 $28
script6b6c:
	checkabutton
	showtext $247c
	jump2byte script6b6c
script6b72:
	asm15 $651b $00
script6b76:
	jumpifmemoryeq $cfc0 $01 script6b5c
	wait 1
	jump2byte script6b76
script6b7f:
	asm15 $6269 $04
	jumpifmemoryset $cddb $80 stubScript
	initcollisions
	jumpifglobalflagset $2f script6c9c
script6b8e:
	asm15 $651b $08
script6b92:
	jumpifinteractionbyteeq $61 $01 script6bac
	jumpifinteractionbyteeq $61 $02 script6bb1
script6b9c:
	jumpifinteractionbyteeq $71 $01 script6c8e
	asm15 $658b
	jumpifmemoryset $cddb $10 script6bb6
	jump2byte script6b92
script6bac:
	asm15 $661a
	jump2byte script6b9c
script6bb1:
	asm15 $661f
	jump2byte script6b9c
script6bb6:
	disableinput
	asm15 $6355
	asm15 scriptHlp.func_5155 $03
	asm15 $655c
script6bc1:
	asm15 objectApplySpeed
	asm15 $656a
	jumpifmemoryset $cddb $80 script6bcf
	jump2byte script6bc1
script6bcf:
	setanimation $01
	setangle $08
script6bd3:
	asm15 objectApplySpeed
	asm15 $657a
	jumpifmemoryset $cddb $80 script6be1
	jump2byte script6bd3
script6be1:
	wait 30
	asm15 $5854 $28
	wait 60
	showtext $247e
	wait 30
	jumpiftextoptioneq $00 script6bf9
script6bef:
	showtext $247f
	wait 30
	jumpiftextoptioneq $00 script6bf9
	jump2byte script6bef
script6bf9:
	showtext $2480
	wait 30
	writeinteractionbyte $50 $28
	setanimation $03
	setangle $18
script6c04:
	asm15 objectApplySpeed
	asm15 $6582
	jumpifmemoryset $cddb $80 script6c12
	jump2byte script6c04
script6c12:
	setanimation $00
	setangle $00
script6c16:
	asm15 objectApplySpeed
	asm15 $6571
	jumpifmemoryset $cddb $80 script6c24
	jump2byte script6c16
script6c24:
	writememory $cfdd $01
	asm15 $651b $03
	wait 20
	asm15 $6914
	wait 50
	asm15 $674e
	asm15 $6986 $00
	wait 22
	writeinteractionbyte $7a $01
	writeinteractionbyte $7b $ff
	asm15 $65c6
script6c44:
	asm15 $6929
	asm15 $65d3
	asm15 $65bd
	jumpifmemoryset $cddb $80 script6c55
	jump2byte script6c44
script6c55:
	playsound $79
	asm15 fadeoutToWhiteWithDelay $04
script6c5b:
	asm15 $6929
	asm15 $65d3
	jumpifmemoryeq $c4ab $00 script6c6a
	wait 1
	jump2byte script6c5b
script6c6a:
	wait 30
	writememory $cfde $00
	spawninteraction $8b00 $50 $38
	writememory $cfc0 $01
	asm15 $6509
	asm15 $65e9
	wait 10
	asm15 fadeinFromWhite
	checkpalettefadedone
	asm15 $65e4
	wait 75
	writememory $cfdf $01
	jump2byte script6ca1
script6c8e:
	disableinput
	asm15 $6509
	writeinteractionbyte $71 $00
	showtext $247d
	wait 30
	enableinput
	jump2byte script6b8e
script6c9c:
	spawninteraction $8b00 $50 $38
script6ca1:
	checkabutton
	showtext $2481
	jump2byte script6ca1
script6ca7:
	initcollisions
	jumpifroomflagset $80 script6d16
	jumpifroomflagset $40 script6cb5
	asm15 $6692
	jump2byte script6cbe
script6cb5:
	asm15 $6689
	jumpifmemoryset $cddb $80 script6d14
script6cbe:
	asm15 $651b $08
script6cc2:
	jumpifinteractionbyteeq $61 $01 script6cd4
	jumpifinteractionbyteeq $61 $02 script6cd9
script6ccc:
	jumpifinteractionbyteeq $71 $01 script6cde
	wait 1
	jump2byte script6cc2
script6cd4:
	asm15 $661a
	jump2byte script6ccc
script6cd9:
	asm15 $661f
	jump2byte script6ccc
script6cde:
	disableinput
	asm15 $6509
	writeinteractionbyte $71 $00
	jumpifroomflagset $40 script6d0f
	showtext $2472
	wait 30
	jumpiftextoptioneq $00 script6cf6
	showtext $2473
	jump2byte script6d0b
script6cf6:
	asm15 $6652
	jumpifmemoryset $cddb $80 script6d04
	showtext $2474
	jump2byte script6d0b
script6d04:
	playsound $5e
	showtext $2475
	orroomflag $40
script6d0b:
	wait 30
	enableinput
	jump2byte script6cbe
script6d0f:
	showtext $2476
	jump2byte script6d0b
script6d14:
	orroomflag $80
script6d16:
	setcoords $38 $58
	jump2byte script6ace
script6d1b:
	disableinput
	writeinteractionbyte $71 $00
	jumpifroomflagset $20 script6d5e
	jumpifmemoryeq $cfc0 $01 script6d5e
	setspeed SPEED_100
	showtext $2477
	wait 30
	jumpiftextoptioneq $00 script6d45
	asm15 $651b $00
	setangle $00
	applyspeed $11
	asm15 $651b $03
	setanimation $03
	setangle $18
	jump2byte script6d55
script6d45:
	asm15 $651b $00
	setangle $00
	applyspeed $11
	asm15 $651b $01
	setanimation $01
	setangle $08
script6d55:
	applyspeed $11
	writememory $cfc0 $01
	enableinput
	jump2byte script6ae0
script6d5e:
	showtext $2478
	wait 30
	enableinput
	jump2byte script6ae3
script6d65:
	initcollisions
	jumpifroomflagset $80 script6d6c
	jump2byte script6ace
script6d6c:
	setcoords $58 $78
	jump2byte script6ace
script6d71:
	loadscript scriptHlp.script15_6a85
script6d75:
	initcollisions
script6d76:
	jumpifinteractionbyteeq $71 $01 script6d84
	jumpifmemoryeq $cfdb $01 script6d96
	wait 1
	jump2byte script6d76
script6d84:
	disableinput
	writeinteractionbyte $71 $00
	showtext $24a8
	wait 30
	jumpiftextoptioneq $00 script6d96
	showtext $24a9
	enableinput
	jump2byte script6d76
script6d96:
	asm15 scriptHlp.shootingGallery_checkLinkHasRupees $04
	jumpifmemoryset $cddb $80 script6da7
script6da0:
	showtext $24aa
	enableinput
	checkabutton
	jump2byte script6da0
script6da7:
	asm15 removeRupeeValue $04
	showtext $24ab
	wait 30
	showtext $24ac
	wait 30
	asm15 $6698
	wait 90
	asm15 fadeoutToWhite
	checkpalettefadedone
	asm15 $677d
	asm15 $674e
	asm15 clearAllItemsAndPutLinkOnGround
	asm15 $6338
	asm15 $67eb
	spawninteraction $1600 $78 $38
	wait 20
	asm15 $6839
	wait 20
	asm15 fadeinFromWhite
	checkpalettefadedone
	wait 40
	setmusic $02
	showtext $24ad
	wait 30
	asm15 $679e
	setdisabledobjectsto00
	jump2byte script6d76
script6de5:
	initcollisions
	jumpifroomflagset $80 script6dfc
script6dea:
	jumpifinteractionbyteeq $71 $01 script6df2
	wait 1
	jump2byte script6dea
script6df2:
	disableinput
	writeinteractionbyte $71 $00
	showtext $24ae
	enableinput
	jump2byte script6dea
script6dfc:
	asm15 $67bd
	jumpifmemoryset $cddb $80 script6e07
	jump2byte script6e0a
script6e07:
	wait 1
	jump2byte script6dfc
script6e0a:
	asm15 $67bd
	jumpifmemoryset $cddb $80 script6e15
	jump2byte script6e0a
script6e15:
	disableinput
	asm15 $5176 $03
	writememory $ccd5 $01
	wait 40
	asm15 $67ae
	asm15 $67cc
	showtext $24af
	wait 30
	asm15 fadeoutToWhite
	checkpalettefadedone
	asm15 clearAllItemsAndPutLinkOnGround
	asm15 $633f
	asm15 $6820
	asm15 $6758
	wait 40
	asm15 fadeinFromWhite
	checkpalettefadedone
	setmusic $ff
	wait 40
	asm15 $67da
	jumpifmemoryset $cddb $80 script6e59
	asm15 $67e2
	jumpifmemoryset $cddb $10 script6e8c
	showtext $24b2
	wait 30
	jump2byte script6e97
script6e59:
	showtext $24b0
	wait 30
	callscript script6e63
	wait 30
	jump2byte script6e97
script6e63:
	jumptable_memoryaddress $cfd6
	.dw script6e70
	.dw script6e74
	.dw script6e7c
	.dw script6e84
	.dw script6e88
script6e70:
	giveitem $5e00
	retscript
script6e74:
	asm15 $511f $0b
	showtext $0006
	retscript
script6e7c:
	asm15 $511f $0c
	showtext $0007
	retscript
script6e84:
	giveitem $3400
	retscript
script6e88:
	giveitem $0602
	retscript
script6e8c:
	showtext $24b1
	asm15 $511f $05
	showtext $0004
	wait 30
script6e97:
	showtext $24b3
	wait 30
	jumpiftextoptioneq $00 script6ea7
	jump2byte script6ea1
script6ea1:
	showtext $24b4
	enableinput
	jump2byte script6dea
script6ea7:
	writememory $cfdb $01
	jump2byte script6dea
script6ead:
	initcollisions
	jump2byte script6ace
script6eb0:
	disableinput
	writeinteractionbyte $71 $00
	jumpifinteractionbyteeq $7c $01 script6eff
	showtext $24c4
	wait 30
	jumpifroomflagset $40 script6f04
	asm15 $686d
	jumptable_interactionbyte $7e
	.dw script6ecc
	.dw script6ef5
	.dw script6efa
script6ecc:
	showtext $24c6
	wait 30
	showtext $24c7
	wait 30
	showtext $24c8
	wait 30
	jumpiftextoptioneq $00 script6ee1
	showtext $24cb
	jump2byte script6f07
script6ee1:
	asm15 loseTreasure $5a
	showtext $24c9
	giveitem $5900
	orroomflag $40
	showtext $24ca
	writeinteractionbyte $7c $01
	jump2byte script6f07
script6ef5:
	showtext $24cd
	jump2byte script6f07
script6efa:
	showtext $24ce
	jump2byte script6f07
script6eff:
	showtext $24cc
	jump2byte script6f07
script6f04:
	showtext $24c5
script6f07:
	enableinput
	jump2byte script6ac3
script6f0a:
	initcollisions
	jump2byte script6ace
script6f0d:
	disableinput
	writeinteractionbyte $71 $00
	jumpifroomflagset $40 script6f42
	showtext $24b5
	wait 30
	jumpifitemobtained $5d script6f22
	showtext $24b6
	jump2byte script6f07
script6f22:
	showtext $24b7
	wait 30
	jumpiftextoptioneq $00 script6f2f
	showtext $24b8
	jump2byte script6f07
script6f2f:
	asm15 loseTreasure $5d
	orroomflag $40
	showtext $24b9
	wait 30
	jumpiftextoptioneq $00 script6f62
	showtext $24ba
	jump2byte script6f07
script6f42:
	showtext $24bf
	wait 30
	jumpiftextoptioneq $00 script6f4f
script6f4a:
	showtext $24c0
	jump2byte script6f07
script6f4f:
	asm15 scriptHlp.shootingGallery_checkLinkHasRupees $04
	jumpifmemoryset $cddb $80 script6f5e
script6f59:
	showtext $24c1
	jump2byte script6f07
script6f5e:
	asm15 removeRupeeValue $04
script6f62:
	showtext $24bb
	wait 30
	jumpiftextoptioneq $00 script6f74
script6f6a:
	showtext $24bd
	wait 30
	jumpiftextoptioneq $00 script6f74
	jump2byte script6f6a
script6f74:
	showtext $24bc
	wait 30
	asm15 $66f2
	wait 60
	showtext $24be
	wait 30
	asm15 fadeoutToWhite
	checkpalettefadedone
	asm15 $68e3
	asm15 clearAllItemsAndPutLinkOnGround
	asm15 $6346
	asm15 $674e
	asm15 $6a6a $04
	wait 8
	callscript script7052
	wait 24
	asm15 fadeinFromWhite
	checkpalettefadedone
	setmusic $02
	wait 40
	playsound $cc
	wait 60
	writememory $cfc0 $00
	asm15 $690a
	enableinput
script6fac:
	jumpifmemoryeq $cfc0 $01 script6fe2
	asm15 $68fe
	jumpifmemoryset $cddb $80 script6fbd
	jump2byte script6fac
script6fbd:
	asm15 $67c5
	jumpifmemoryset $cddb $80 script6fc8
	jump2byte script6fbd
script6fc8:
	disableinput
	writeinteractionbyte $71 $00
	playsound $65
	asm15 $5176 $02
	wait 2
	writememory $cc50 $02
	wait 80
	showtext $24e1
	callscript script702b
	jump2byte script700f
script6fe2:
	asm15 $67c5
	jumpifmemoryset $cddb $80 script6fed
	jump2byte script6fe2
script6fed:
	disableinput
	playsound $cc
	writeinteractionbyte $71 $00
	wait 60
	asm15 $5176 $02
	wait 2
	playsound $ab
	writememory $cc50 $08
	wait 60
	showtext $24e0
	callscript script702b
	showtext $24c3
	wait 30
	callscript script706a
	wait 30
script700f:
	showtext $24c2
	wait 30
	jumpiftextoptioneq $00 script7019
	jump2byte script6f4a
script7019:
	asm15 scriptHlp.shootingGallery_checkLinkHasRupees $04
	jumpifmemoryset $cddb $80 script7025
	jump2byte script6f59
script7025:
	asm15 removeRupeeValue $04
	jump2byte script6f74
script702b:
	wait 30
	asm15 fadeoutToWhite
	checkpalettefadedone
	asm15 $68f0
	asm15 clearAllItemsAndPutLinkOnGround
	asm15 $6346
	asm15 clearParts
	asm15 $6a6a $00
	wait 8
	asm15 $69c8
	wait 8
	asm15 $69cf
	wait 24
	asm15 fadeinFromWhite
	checkpalettefadedone
	setmusic $ff
	wait 40
	retscript
script7052:
	getrandombits $7d $01
	jumpifinteractionbyteeq $7d $01 script7062
	asm15 $69ac
	wait 8
	asm15 $69b3
	retscript
script7062:
	asm15 $69ba
	wait 8
	asm15 $69c1
	retscript
script706a:
	jumptable_memoryaddress $cfd6
	.dw script7079
	.dw script707d
	.dw script7085
	.dw script708d
	.dw script7091
	.dw script7095
script7079:
	giveitem $4500
	retscript
script707d:
	asm15 $511f $0c
	showtext $0007
	retscript
script7085:
	asm15 $511f $07
	showtext $0005
	retscript
script708d:
	giveitem $3400
	retscript
script7091:
	giveitem $2d14
	retscript
script7095:
	giveitem $2d15
	retscript
script7099:
	asm15 $6423
	jumpifinteractionbyteeq $72 $ff stubScript
	initcollisions
script70a2:
	checkabutton
	showloadedtext
	jump2byte script70a2
script70a6:
	asm15 $6423
	jumpifinteractionbyteeq $72 $ff stubScript
	jump2byte script6a7a
script70b0:
	disableinput
	writeinteractionbyte $71 $00
	asm15 $5ca8
	showloadedtext
	asm15 $6556
	enableinput
	jump2byte script6a7e
script70be:
	asm15 $6423
	jumpifinteractionbyteeq $72 $ff stubScript
	initcollisions
	jump2byte script6ace
script70c9:
	disableinput
	writeinteractionbyte $71 $00
	showloadedtext
	enableinput
	jump2byte script6ae3
script70d1:
	initcollisions
	writeinteractionbyte $5c $00
script70d5:
	checkabutton
	disableinput
	asm15 $6888
	wait 1
	enableinput
	jump2byte script70d5
script70de:
	initcollisions
	checkabutton
	disableinput
	asm15 $5ca8
	showtextlowindex $10
	wait 30
	setspeed SPEED_020
	movenpcright $30
	wait 20
	writeinteractionbyte $7e $09
	wait 20
	writeinteractionbyte $7e $f7
	writeinteractionbyte $48 $01
	setanimation $03
	wait 30
	showtextlowindex $11
	wait 30
	writeinteractionbyte $7e $ff
	giveitem $1501
	wait 30
	orroomflag $40
	enableinput
	jump2byte script7109
script7108:
	initcollisions
script7109:
	checkabutton
	showtextlowindex $12
	jump2byte script7109
script710e:
	asm15 $5180
	jumpifmemoryset $cddb $80 stubScript
	rungenericnpclowindex $13
script7119:
	initcollisions
	jumptable_interactionbyte $78
	.dw script7126
	.dw script7133
	.dw script713f
	.dw script7169
	.dw script716e
script7126:
	settextid $2700
script7129:
	checkabutton
	asm15 $5ca8
script712d:
	showloadedtext
	enableinput
	setanimation $02
	jump2byte script7129
script7133:
	checkabutton
	callscript script717f
	showtextlowindex $00
	wait 20
	settextid $2701
	jump2byte script712d
script713f:
	checkabutton
	callscript script717f
	wait 20
	asm15 $5854 $3c
	wait 30
	showtextlowindex $02
	wait 30
script714c:
	showtextlowindex $03
	jumpiftextoptioneq $00 script715e
	wait 20
	showtextlowindex $04
	enableinput
	setanimation $02
	checkabutton
	callscript script717f
	jump2byte script714c
script715e:
	asm15 loseTreasure $52
	wait 20
	showtextlowindex $05
	wait 20
	setglobalflag $15
	enableinput
script7169:
	settextid $2706
	jump2byte script7129
script716e:
	disableinput
	wait 100
	writeinteractionbyte $60 $7f
	showtextlowindex $07
	wait 30
	setspeed SPEED_100
	movenpcright $40
	setglobalflag $26
	enableinput
	scriptend
script717f:
	disableinput
	asm15 $5ca8
	writeinteractionbyte $60 $7f
	retscript
script7187:
	loadscript scriptHlp.script15_6b3d
script718b:
	initcollisions
	setcollisionradii $0c $06
	jumpifitemobtained $52 script719b
script7193:
	checkabutton
	showtextlowindex $0c
	asm15 $6b7f
	jump2byte script7193
script719b:
	checkabutton
	showtextlowindex $0d
	asm15 $6b7f
	jump2byte script719b
script71a3:
	scriptend
script71a4:
	jumpifroomflagset $40 script71c7
	asm15 $6bc0
	jumpifmemoryset $cddb $80 script71c7
	setcollisionradii $04 $18
	checkcollidedwithlink_ignorez
	disableinput
	asm15 $517a
	wait 40
	spawninteraction $3701 $50 $b0
	checkmemoryeq $cfc0 $01
	wait 40
	orroomflag $40
	enableinput
script71c7:
	scriptend
script71c8:
	loadscript scriptHlp.script15_6be7
script71cc:
	asm15 restartSound
	wait 120
	playsound $21
	writeinteractionbyte $78 $04
script71d5:
	asm15 darkenRoom
	checkpalettefadedone
	wait 8
	asm15 brightenRoom
	checkpalettefadedone
	wait 8
	addinteractionbyte $78 $ff
	jumpifinteractionbyteeq $78 $00 script71e9
	jump2byte script71d5
script71e9:
	wait 30
	writememory $cfd1 $02
	wait 90
	writeinteractionbyte $78 $0a
script71f2:
	asm15 darkenRoom_variant $04
	checkpalettefadedone
	wait 4
	asm15 brightenRoomWithSpeed $04
	checkpalettefadedone
	wait 4
	addinteractionbyte $78 $ff
	jumpifinteractionbyteeq $78 $00 script7208
	jump2byte script71f2
script7208:
	asm15 darkenRoom_variant $02
	checkpalettefadedone
	scriptend
script720e:
	setcollisionradii $02 $02
script7211:
	asm15 $6bc8
	wait 1
	jumpifinteractionbyteeq $78 $00 script7211
	disableinput
	asm15 objectSetInvisible
	writeinteractionbyte $45 $01
	jumptable_interactionbyte $43
	.dw script7229
	.dw script7231
	.dw script723a
script7229:
	asm15 $6be1
	giveitem $0304
	wait 30
	scriptend
script7231:
	giveitem $5200
	writememory $cc24 $00
	wait 30
	scriptend
script723a:
	giveitem $2e00
	wait 30
	scriptend
simpleScript723f:
	ss_settile $68 $9e
	ss_setcounter1 $28
	ss_playsound $70
	ss_setinterleavedtile $43 $fa $1d $3
	ss_setinterleavedtile $45 $fa $1d $1
	ss_setinterleavedtile $53 $f4 $1e $3
	ss_setinterleavedtile $55 $f4 $1e $1
	ss_setcounter1 $28
	ss_playsound $70
	ss_settile $43 $1d
	ss_settile $45 $1d
	ss_settile $53 $1e
	ss_settile $55 $1e
	ss_setcounter1 $28
	ss_playsound $70
	ss_settile $44 $1d
	ss_settile $54 $1e
	ss_setcounter1 $28
	ss_playsound $4d
	ss_end
script7279:
	checkmemoryeq $cfc0 $01
	setanimation $04
	checkmemoryeq $cfc0 $03
	wait 60
	writememory $cfc0 $04
	setspeed SPEED_040
	setangle $10
	scriptend
script728d:
	loadscript scriptHlp.script15_6cd7
script7291:
	loadscript scriptHlp.script15_6d03
script7295:
	loadscript scriptHlp.script15_6d14
script7299:
	asm15 $6d38
	wait 30
	setanimation $03
	wait 16
	setanimation $02
	wait 16
	showtext $5608
	asm15 $6d27
	wait 12
	showtext $5609
	wait 8
	writeinteractionbyte $77 $01
	checkinteractionbyteeq $77 $00
	scriptend
script72b8:
	asm15 $c98 $98
	applyspeed $1e
	wait 30
	showtext $560a
	wait 15
	writeinteractionbyte $49 $10
	applyspeed $14
	wait 8
	scriptend
script72ca:
	wait 30
	spawninteraction $6e01 $b0 $78
	checkmemoryeq $cfd0 $02
	wait 30
	setanimation $02
	showtext $1d04
	writememory $cfd0 $01
	checkmemoryeq $cfd0 $02
	wait 60
	applyspeed $1e
	checkmemoryeq $cfd0 $06
	setanimation $03
	wait 8
	showtext $1d05
	wait 30
	writememory $cfd0 $01
	checkmemoryeq $cfd0 $02
	setanimation $02
	wait 60
	setanimation $0b
	asm15 $6d45
	wait 60
	scriptend
script7302:
	wait 30
	showtext $1308
	asm15 $c98 $1f
	setanimation $04
	applyspeed $30
	writememory $cfd0 $02
	checkmemoryeq $cfd0 $01
	asm15 $6d5e $00
	wait 20
	showtext $1309
	writememory $cfd0 $02
	spawninteraction $6e02 $00 $34
	scriptend
script7328:
	wait 60
	setanimation $04
	wait 30
	showtext $560d
	writememory $cfd0 $02
	wait 15
	asm15 $6d51 $00
	asm15 $6d51 $01
	asm15 $6d51 $02
	asm15 $6d51 $03
	asm15 $6d51 $04
	asm15 $6d51 $05
	checkmemoryeq $cfd0 $08
	wait 30
	spawninteraction $6e03 $b0 $78
	checkmemoryeq $cfd0 $03
	setanimation $06
	checkmemoryeq $cfd0 $04
	setanimation $07
	checkmemoryeq $cfd0 $05
	setanimation $04
	checkmemoryeq $cfd0 $01
	wait 30
	writememory $d008 $02
	asm15 $6d5e $01
	wait 1
	asm15 $6d5e $01
	wait 15
	showtext $130a
	wait 15
	writememory $cfd0 $02
script7383:
	wait 240
	jump2byte script7383
script7386:
	showtext $2a0c
	writememory $cfd0 $03
	setanimation $10
	applyspeed $10
	asm15 $6d6e $00
	applyspeed $08
	writememory $cfd0 $04
	asm15 $6d6e $01
	applyspeed $13
	writememory $d008 $03
	writememory $cfd0 $05
	applyspeed $10
	setanimation $11
	writememory $d008 $00
	wait 16
	writememory $cfd0 $06
	wait 2
	showtext $2a0d
	jump2byte script7383
script73be:
	applyspeed $10
	asm15 $6d6e $04
	applyspeed $20
	asm15 $6d6e $02
	applyspeed $42
	asm15 $6d6e $03
	applyspeed $15
	setanimation $0e
script73d4:
	checkmemoryeq $cfd0 $03
	setanimation $0e
	checkmemoryeq $cfd0 $04
	asm15 $6d9e
	checkmemoryeq $cfd0 $05
	asm15 $6d84
	checkmemoryeq $cfd0 $01
	checkmemoryeq $cfd0 $02
script73f0:
	applyspeed $08
	wait 30
	jump2byte script73f0
script73f5:
	wait 45
	applyspeed $10
	asm15 $6d6e $03
	applyspeed $20
	asm15 $6d6e $02
	applyspeed $42
	asm15 $6d6e $04
	applyspeed $15
	setanimation $0e
	jump2byte script73d4
script740f:
	wait 90
	applyspeed $10
	asm15 $6d6e $04
	applyspeed $20
	asm15 $6d6e $02
	applyspeed $23
	asm15 $6d6e $03
	applyspeed $0a
	jump2byte script73d4
script7426:
	wait 135
	applyspeed $10
	asm15 $6d6e $03
	applyspeed $20
	asm15 $6d6e $02
	applyspeed $23
	asm15 $6d6e $04
	applyspeed $0a
	jump2byte script73d4
script743e:
	wait 180
	applyspeed $10
	asm15 $6d6e $04
	applyspeed $12
	asm15 $6d6e $02
	applyspeed $0f
	jump2byte script73d4
script744f:
	wait 225
	applyspeed $10
	asm15 $6d6e $03
	applyspeed $12
	asm15 $6d6e $02
	applyspeed $0f
	writememory $cfd0 $08
	jump2byte script73d4
script7465:
	jumpifmemoryset $d13e $02 script746d
	jump2byte script7465
script746d:
	writeinteractionbyte $7a $3c
	callscript script74d6
	showtext $2200
	ormemory $d13e $04
script747a:
	jumpifmemoryset $d13e $10 script7482
	jump2byte script747a
script7482:
	checkmemoryeq $cdd1 $00
	playsound $c8
	wait 20
	playsound $c8
	wait 20
	playsound $c8
	asm15 $6dcc
	writememory $d103 $02
	checkmemoryeq $d13d $01
	writeinteractionbyte $7a $3c
	callscript script74d6
	showtext $2201
	writememory $d103 $03
	asm15 $6db6
	setdisabledobjectsto11
	asm15 $6dbe
	wait 60
	jumpifmemoryeq $cc01 $00 script74c1
	jumpifmemoryeq $c610 $0d script74bc
	jump2byte script74c1
script74bc:
	showtext $2204
	jump2byte script74c4
script74c1:
	showtext $2203
script74c4:
	ormemory wMooshState $20
	setdisabledobjectsto00
	checkmemoryeq $cc2c $d1
	showtext $2205
	writememory $cc91 $00
	enablemenu
	scriptend
script74d6:
	jumpifinteractionbyteeq $7a $00 script74de
	wait 1
	jump2byte script74d6
script74de:
	retscript
script74df:
	loadscript scriptHlp.script15_6e73
script74e3:
	loadscript scriptHlp.script15_6e01
script74e7:
	checkmemoryeq $cc2c $d0
	checkmemoryeq $cc5c $00
	writememory $cbc3 $00
	disablemenu
	setdisabledobjectsto11
	turntofacelink
	showtext $2104
	writememory $d103 $03
	writememory $cc91 $00
	scriptend
script7502:
	loadscript scriptHlp.script15_6e4b
script7506:
	loadscript scriptHlp.script15_6eef
script750a:
	loadscript scriptHlp.script15_6eb6
script750e:
	loadscript scriptHlp.script15_6df0
script7512:
	wait 70
	showtext $2f1b
	wait 1
	writememory $cfd0 $01
	setanimation $00
script751e:
	applyspeed $40
	scriptend
script7521:
	checkmemoryeq $cfd0 $01
	setanimation $02
	jump2byte script751e
script7529:
	wait 30
	applyspeed $10
	wait 20
	setspeed SPEED_100
	applyspeed $18
	checkmemoryeq $cfd0 $02
	asm15 $6f13 $02
	applyspeed $30
	scriptend
script753c:
	wait 60
	applyspeed $10
	wait 20
	setspeed SPEED_100
	applyspeed $10
	checkmemoryeq $cfd0 $02
	asm15 $6f13 $01
	applyspeed $18
	scriptend
script754f:
	wait 90
	applyspeed $10
	wait 20
	setspeed SPEED_100
	applyspeed $18
	asm15 $6f13 $03
	applyspeed $18
	setanimation $04
	checkmemoryeq $cfd0 $02
	asm15 $6f13 $01
	applyspeed $18
	asm15 $6f13 $02
	applyspeed $20
	scriptend
script7570:
	wait 120
	applyspeed $10
	wait 20
	setspeed SPEED_100
	applyspeed $28
	wait 60
	showtext $3128
	giveitem $4900
	wait 30
	showtext $3129
	writememory $cfd0 $02
	asm15 $6f13 $02
	applyspeed $30
	asm15 $6f27
	scriptend
script7591:
	setdisabledobjectsto11
	asm15 $6f32
script7595:
	jumpifinteractionbyteeq $50 $00 script759d
	wait 1
	jump2byte script7595
script759d:
	showtext $1204
	ormemory $d13e $01
script75a4:
	jumpifmemoryset $d13e $10 script75ac
	jump2byte script75a4
script75ac:
	setdisabledobjectsto00
	spawnenemyhere $1700
	scriptend
script75b1:
	jumpifmemoryset $d13e $01 script75b9
	jump2byte script75b1
script75b9:
	asm15 $6f32
script75bc:
	jumpifinteractionbyteeq $50 $00 script75c4
	wait 1
	jump2byte script75bc
script75c4:
	showtext $1205
	ormemory $d13e $02
script75cb:
	jumpifmemoryset $d13e $08 script75d3
	jump2byte script75cb
script75d3:
	asm15 $6f32
script75d6:
	jumpifinteractionbyteeq $50 $00 script75de
	wait 1
	jump2byte script75d6
script75de:
	showtext $1207
	playsound $c8
	setmusic $2d
	ormemory $d13e $10
	spawnenemyhere $1700
	scriptend
script75ed:
	jumpifmemoryset $d13e $04 script75f5
	jump2byte script75ed
script75f5:
	asm15 $6f32
script75f8:
	jumpifinteractionbyteeq $50 $00 script7600
	wait 1
	jump2byte script75f8
script7600:
	showtext $1206
	ormemory $d13e $08
script7607:
	jumpifmemoryset $d13e $10 script760f
	jump2byte script7607
script760f:
	spawnenemyhere $1700
	scriptend
script7613:
	enableinput
	wait 1
	checktext
	checkabutton
	disableinput
	jumptable_interactionbyte $42
	.dw script7628
	.dw script766c
	.dw script76b4
	.dw script76c4
	.dw script76dc
	.dw script76dc
	.dw script76dc
script7628:
	jumpifinteractionbyteeq $79 $00 script7649
	showtextlowindex $2b
	jumptable_memoryaddress wSelectedTextOption
	.dw script7636
	.dw script76d4
script7636:
	jumpifinteractionbyteeq $78 $00 script7645
	asm15 $6f8e
	asm15 $6f75
	setglobalflag $36
	enableinput
	scriptend
script7645:
	showtextlowindex $2e
	jump2byte script7613
script7649:
	jumpifinteractionbyteeq $7a $00 script765c
	showtextlowindex $2c
	jumptable_memoryaddress wSelectedTextOption
	.dw script7657
	.dw script76d4
script7657:
	asm15 $6f3d
	jump2byte script7613
script765c:
	showtextlowindex $27
	jumptable_memoryaddress wSelectedTextOption
	.dw script7665
	.dw script76d8
script7665:
	showtextlowindex $28
	asm15 $6f4d
	jump2byte script7613
script766c:
	jumpifinteractionbyteeq $79 $00 script7691
	showtextlowindex $32
	jumptable_memoryaddress wSelectedTextOption
	.dw script767a
	.dw script76d4
script767a:
	jumpifinteractionbyteeq $78 $00 script768d
	asm15 $6f8a
	asm15 $6f71
	setglobalflag $37
	wait 1
	checktext
	showtextlowindex $3b
	enableinput
	scriptend
script768d:
	showtextlowindex $34
	jump2byte script7613
script7691:
	jumpifinteractionbyteeq $7a $00 script76a4
	showtextlowindex $33
	jumptable_memoryaddress wSelectedTextOption
	.dw script769f
	.dw script76d4
script769f:
	asm15 $6f43
	jump2byte script7613
script76a4:
	showtextlowindex $30
	jumptable_memoryaddress wSelectedTextOption
	.dw script76ad
	.dw script76d8
script76ad:
	showtextlowindex $28
	asm15 $6f49
	jump2byte script7613
script76b4:
	showtextlowindex $36
	jumptable_memoryaddress wSelectedTextOption
	.dw script76bd
	.dw script76d8
script76bd:
	showtextlowindex $28
	asm15 $6f49
	jump2byte script7613
script76c4:
	showtextlowindex $35
	jumptable_memoryaddress wSelectedTextOption
	.dw script76cd
	.dw script76d8
script76cd:
	showtextlowindex $28
	asm15 $6f4d
	jump2byte script7613
script76d4:
	showtextlowindex $2d
	jump2byte script7613
script76d8:
	showtextlowindex $29
	jump2byte script7613
script76dc:
	showtextlowindex $39
	jumptable_memoryaddress wSelectedTextOption
	.dw script76e5
	.dw script76d4
script76e5:
	jumpifinteractionbyteeq $7d $00 script76ee
	showtextlowindex $3a
	jump2byte script7613
script76ee:
	jumpifinteractionbyteeq $78 $00 script76fb
	asm15 $6f8a
	asm15 $6f64
	enableinput
	scriptend
script76fb:
	showtextlowindex $34
	jump2byte script7613
script76ff:
	loadscript scriptHlp.script15_6ff7
script7703:
	loadscript scriptHlp.script15_7139
script7707:
	loadscript scriptHlp.script15_71bd
script770b:
	loadscript scriptHlp.script15_71ef
script770f:
	jumpifmemoryeq $cfd0 $03 script771d
	checkmemoryeq $cfd0 $01
	checkpalettefadedone
	setanimation $01
	scriptend
script771d:
	checkpalettefadedone
	wait 40
	setanimation $04
	showtextlowindex $53
	wait 30
	writememory $cfd0 $04
	checkmemoryeq $cfd0 $05
	setanimation $00
	checkmemoryeq $cfd0 $06
	setanimation $03
	checkmemoryeq $cfd0 $07
	setanimation $02
	checkmemoryeq $cfd0 $0b
	wait 80
	asm15 scriptHlp.func_5155 $00
	wait 40
	jumpifmemoryeq $cc01 $00 script774f
	showtextlowindex $57
	jump2byte script7751
script774f:
	showtextlowindex $54
script7751:
	wait 80
	setanimation $00
	wait 40
	setcollisionradii $08 $08
	makeabuttonsensitive
script775a:
	showtextlowindex $55
	wait 20
	setanimation $04
	wait 20
	showtextlowindex $56
	writememory $c6e6 $56
	wait 20
	setanimation $00
	writememory $cfd0 $63
	enableinput
	checkabutton
	disableinput
	jump2byte script775a
script7772:
	checkmemoryeq $cfc0 $06
	wait 20
	setanimation $02
	scriptend
script777a:
	checkmemoryeq $cfc0 $01
	setanimation $03
	checkmemoryeq $cfc0 $02
	showtextlowindex $52
	wait 60
	writememory $cfc0 $03
	checkmemoryeq $cfc0 $08
	wait 150
	setanimation $02
	scriptend
script7794:
	loadscript scriptHlp.script15_7287
script7798:
	loadscript scriptHlp.script15_72a4
script779c:
	jumpifmemoryeq $cc01 $01 script77a4
	rungenericnpclowindex $5c
script77a4:
	rungenericnpclowindex $60
script77a6:
	loadscript scriptHlp.script15_72d0
script77aa:
	jumpifglobalflagset $12 script77d1
	spawninteraction $6b04 $40 $50
	setanimation $02
	setcollisionradii $08 $08
	checkmemoryeq $cfc0 $09
	wait 2
script77be:
	jumptable_memoryaddress $cdd1
	.dw script77ce
	.dw script77c7
	.dw script77be
script77c7:
	setanimation $01
	wait 90
	setanimation $00
	wait 60
	checknoenemies
script77ce:
	setanimation $01
	wait 90
script77d1:
	setanimation $00
	setcollisionradii $08 $08
	makeabuttonsensitive
script77d7:
	checkabutton
	showtextlowindex $d5
	jump2byte script77d7
script77dc:
	disableinput
	writememory $cbae $04
	setmusic $1e
	wait 40
	writememory $cbe7 $77
	asm15 hideStatusBar
	asm15 $7318 $02
	checkpalettefadedone
	jumpifinteractionbyteeq $42 $01 script77fe
	spawninteraction $6200 $00 $00
	wait 240
	wait 180
	jump2byte script7805
script77fe:
	spawninteraction $6201 $00 $00
	wait 240
	wait 60
script7805:
	asm15 $7082 $00
	wait 1
	asm15 showStatusBar
	asm15 clearFadingPalettes
	asm15 $7333
	asm15 fadeinFromWhiteWithDelay $02
	checkpalettefadedone
	setmusic $ff
	orroomflag $40
	asm15 incMakuTreeState
	jumpifinteractionbyteeq $43 $07 script7826
	enableinput
	scriptend
script7826:
	spawninteraction $6603 $58 $a8
	scriptend
script782c:
	loadscript scriptHlp.script15_7355
script7830:
	loadscript scriptHlp.script15_7397
script7834:
	loadscript scriptHlp.script15_73ac
script7838:
	loadscript scriptHlp.script15_73c9
script783c:
	checkcfc0bit 0
	setmusic $f0
	wait 60
	asm15 $73d5
	wait 30
	asm15 $73d9
	wait 30
	asm15 $73dd
	wait 30
	settilehere $ee
script784e:
	wait 45
	setmusic $ff
	playsound $4d
	enableinput
	scriptend
script7856:
	checkcfc0bit 0
	setmusic $f0
	wait 60
	playsound $70
	settilehere $af
	jump2byte script784e
script7860:
	checkcfc0bit 0
	setmusic $f0
	wait 60
	playsound $70
	settileat $22 $ee
	settileat $23 $ef
	jump2byte script784e
script786e:
	loadscript scriptHlp.script15_742b
script7872:
	loadscript scriptHlp.script15_746b
script7876:
	loadscript scriptHlp.script15_747b
script787a:
	loadscript scriptHlp.script15_7490
script787e:
	loadscript scriptHlp.script15_7501
script7882:
	loadscript scriptHlp.script15_7541
script7886:
	initcollisions
script7887:
	checkabutton
	showtext $5811
	jump2byte script7887
script788d:
	movenpcup $14
	wait 8
	movenpcright $32
	wait 1
	setanimation $03
	wait 30
	scriptend
script7897:
	loadscript scriptHlp.script15_7567
script789b:
	wait 8
	setanimation $06
script789e:
	checkabutton
	showtext $580b
	jump2byte script789e
script78a4:
	wait 30
	asm15 fadeoutToWhiteWithDelay $02
	wait 1
	setanimation $02
	asm15 $74d4
	wait 3
	asm15 fadeinFromWhiteWithDelay $02
	wait 30
	asm15 $74b0
	showtext $580d
	setanimation $04
	writememory $cfd3 $01
	wait 60
	asm15 $74f1
	wait 4
	showtext $580e
	callscript script78d5
	wait 60
	showtext $580f
	asm15 $74b7
	scriptend
script78d5:
	jumptable_memoryaddress $cfd0
	.dw script78dc
	.dw script78e0
script78dc:
	giveitem $4c01
	retscript
script78e0:
	jumptable_memoryaddress $cfd1
	.dw script78ef
	.dw script78e7
script78e7:
	giveitem $0501
	giveitem $0504
	jump2byte script78f5
script78ef:
	giveitem $0502
	giveitem $0505
script78f5:
	asm15 loseTreasure $41
	retscript
script78fa:
	asm15 $74d4
	asm15 $74f1
	asm15 fadeinFromWhiteWithDelay $04
	wait 120
	asm15 $74b0
	showtext $580c
	asm15 $74b7
	setanimation $02
	scriptend
script7911:
	initcollisions
script7912:
	checkabutton
	showtext $580f
	jump2byte script7912
script7918:
	setanimation $03
	checkmemoryeq $cfc0 $01
	writeinteractionbyte $7f $01
	callscript script51ac
	writeinteractionbyte $7f $00
	writememory $cfc0 $02
	checkmemoryeq $cfc0 $05
script792f:
	writeinteractionbyte $7f $01
	callscript script51ac
	writeinteractionbyte $7f $00
	jumpifmemoryeq $cfc0 $06 script7941
	wait 30
	jump2byte script792f
script7941:
	asm15 $5ca8
	asm15 $51a6 $01
	checkmemoryeq $ccd4 $02
	asm15 $51ab $01
	checkmemoryeq $cfc0 $09
	asm15 $7592
	wait 1
	scriptend
script7959:
	setanimation $01
	checkmemoryeq $cfc0 $03
	writeinteractionbyte $7f $01
	callscript script51ac
	writeinteractionbyte $7f $00
	writememory $cfc0 $04
	checkmemoryeq $cfc0 $05
	wait 30
	jump2byte script792f
script7973:
	loadscript scriptHlp.script15_75b3
script7977:
	makeabuttonsensitive
script7978:
	setanimation $02
	checkabutton
	jumpifinteractionbyteeq $7f $00 script7982
	jump2byte script7abe
script7982:
	jumpifmemoryeq $cfd0 $01 script79b6
	showtextlowindex $0c
	jump2byte script7978
script798c:
	makeabuttonsensitive
script798d:
	setanimation $02
	checkabutton
	jumpifinteractionbyteeq $7f $00 script7997
	jump2byte script7abe
script7997:
	jumpifmemoryeq $cfd0 $01 script79b6
	showtextlowindex $0d
	jump2byte script798d
script79a1:
	makeabuttonsensitive
script79a2:
	setanimation $02
	checkabutton
	jumpifinteractionbyteeq $7f $00 script79ac
	jump2byte script7abe
script79ac:
	jumpifmemoryeq $cfd0 $01 script79b6
	showtextlowindex $0e
	jump2byte script79a2
script79b6:
	disableinput
	showtextlowindex $0f
	setanimation $03
	writeinteractionbyte $44 $02
	scriptend
script79bf:
	disableinput
	callscript script7aa6
	showtextlowindex $0a
	writememory $cfd0 $02
	checkmemoryeq $cfd0 $03
	setanimation $04
	checkmemoryeq $cfd0 $07
	setanimation $05
	checkmemoryeq $cfd0 $08
	callscript script7aa6
	showtextlowindex $0b
	writememory $cfd0 $09
	checkmemoryeq $cfd0 $0a
	setanimation $04
	wait 10
	writememory $cfd0 $0b
	setspeed SPEED_100
	writeinteractionbyte $49 $10
	applyspeed $30
	scriptend
script79f5:
	checkmemoryeq $cfd0 $02
	callscript script7aa6
	showtextlowindex $11
	writememory $cfd0 $03
	setspeed SPEED_100
	movenpcdown $10
	movenpcleft $30
	wait 90
	asm15 $759b $52
	movenpcleft $10
	wait 90
	asm15 $759b $51
	movenpcleft $10
	wait 90
	asm15 $759b $50
	movenpcright $50
	movenpcup $10
	writememory $cfd0 $07
	setanimation $03
	callscript script7aa6
	wait 10
	showtextlowindex $12
	writememory $cfd0 $08
	checkmemoryeq $cfd0 $09
	showtextlowindex $11
	writememory $cfd0 $0a
	wait 90
	movenpcdown $30
	scriptend
script7a3d:
	callscript script7a74
	setspeed SPEED_100
	movenpcdown $10
	movenpcleft $20
	callscript script7a82
	movenpcright $40
	movenpcup $10
	setanimation $02
	callscript script7a93
	wait 180
	movenpcdown $40
	scriptend
script7a56:
	callscript script7a74
	setspeed SPEED_100
	movenpcdown $28
	movenpcleft $10
	callscript script7a82
	movenpcright $30
	movenpcup $28
	setanimation $02
	callscript script7a93
	wait 180
	wait 90
	movenpcdown $50
	setdisabledobjectsto00
	setglobalflag $25
	enablemenu
	scriptend
script7a74:
	checkmemoryeq $cfd0 $02
	setzspeed -$0200
	wait 20
	retscript
script7a7d:
	checkmemoryeq $cfd0 $03
	retscript
script7a82:
	checkmemoryeq $cfd0 $04
	movenpcleft $10
	checkmemoryeq $cfd0 $05
	movenpcleft $10
	checkmemoryeq $cfd0 $06
	retscript
script7a93:
	setzspeed -$0200
	wait 20
	retscript
script7a98:
	checkmemoryeq $cfd0 $09
	setzspeed -$0200
	wait 20
	retscript
script7aa1:
	checkmemoryeq $cfd0 $0a
	retscript
script7aa6:
	setzspeed -$0200
	playsound $53
	wait 20
	retscript
script7aad:
	initcollisions
script7aae:
	setanimation $00
	checkabutton
	turntofacelink
	jumpifglobalflagset $30 script7aba
	showtextlowindex $13
	jump2byte script7aae
script7aba:
	showtextlowindex $14
	jump2byte script7aae
script7abe:
	turntofacelink
	showtextlowindex $10
	setanimation $02
	checkabutton
	jump2byte script7abe
script7ac6:
	loadscript scriptHlp.script15_75e7
script7aca:
	checkabutton
	showtextnonexitable $3408
	jumpiftextoptioneq $00 script7adf
	orroomflag $40
script7ad4:
	showtext $340a
script7ad7:
	checkabutton
	showtextnonexitable $3409
	jumpiftextoptioneq $01 script7ad4
script7adf:
	disableinput
	showtext $340b
	giveitem $4600
	wait 60
	showtext $340c
	enableinput
script7aeb:
	checkabutton
	showtext $340c
	jump2byte script7aeb
script7af1:
	checkabutton
	showtext $340d
	asm15 setGlobalFlag $31
script7af9:
	checkabutton
	showtext $340e
	jump2byte script7af9
script7aff:
	checkabutton
	showtext $340f
	jump2byte script7aff
script7b05:
	checkabutton
	disableinput
	jumpifglobalflagset $6e script7b3d
	showtext $3435
	wait 30
	jumpiftextoptioneq $00 script7b18
	showtext $3436
	jump2byte script7b42
script7b18:
	askforsecret $00
	wait 30
	jumpifmemoryeq $cc89 $00 script7b26
	showtext $3438
	jump2byte script7b42
script7b26:
	setglobalflag $64
	showtext $3437
	wait 30
	callscript script518b
	wait 30
	callscript script7b45
	wait 30
	generatesecret $00
	setglobalflag $6e
	showtext $3439
	jump2byte script7b42
script7b3d:
	generatesecret $00
	showtext $343a
script7b42:
	enableinput
	jump2byte script7b05
script7b45:
	jumptable_interactionbyte $43
	.dw script7b52
	.dw script7b4b
script7b4b:
	giveitem $0501
	giveitem $0504
	retscript
script7b52:
	giveitem $0502
	giveitem $0505
	retscript
script7b59:
	checkabutton
	showtext $3400
	jump2byte script7b59
script7b5f:
	checkabutton
	showtext $3401
	jumpiftextoptioneq $01 script7b5f
	disableinput
	wait 8
	spawninteraction $9c02 $34 $78
	asm15 loseTreasure $2f
	asm15 $c98 $00
	wait 30
	showtext $3402
	wait 8
	asm15 $c98 $00
	showtext $3403
	wait 60
	showtext $3404
	asm15 setGlobalFlag $27
	enableinput
script7b8b:
	checkabutton
	showtext $3405
	jump2byte script7b8b
script7b91:
	checkabutton
	showtext $3406
	jump2byte script7b91
script7b97:
	checkabutton
	showtext $3407
	jump2byte script7b97
script7b9d:
	initcollisions
	setcollisionradii $14 $06
	jumpifroomflagset $40 script7bae
	checkabutton
	setdisabledobjectsto91
	showtextlowindex $00
	disableinput
	xorcfc0bit 0
	enableinput
	rungenericnpclowindex $01
script7bae:
	rungenericnpclowindex $04
script7bb0:
	disableinput
	loadscript scriptHlp.script15_766e
script7bb5:
	movenpcright $20
	wait 15
	movenpcleft $20
	wait 15
	asm15 $7654
	movenpcright $20
	wait 15
	asm15 $7654
	movenpcleft $20
	wait 15
	retscript
script7bc8:
	movenpcleft $10
	setanimation $02
	wait 15
	movenpcleft $10
	setanimation $02
	wait 15
	movenpcright $10
	setanimation $02
	wait 15
	movenpcright $10
	setanimation $02
	wait 15
	retscript
script7bdd:
	setanimation $05
	setcollisionradii $08 $04
	makeabuttonsensitive
	checkabutton
	setdisabledobjectsto11
	setanimation $06
	wait 220
	showtext $3d05
	wait 60
	writememory wCutsceneTrigger $0f
	scriptend
script7bf2:
	wait 60
	setanimation $03
	wait 30
	setanimation $01
	wait 30
	asm15 $76de
	setanimation $02
	wait 20
	asm15 $76e6
	wait 8
	movenpcdown $11
	movenpcright $17
script7c07:
	wait 30
	xorcfc0bit 7
	scriptend
script7c0a:
	wait 60
	setanimation $01
	wait 30
	setanimation $03
	wait 30
	asm15 $76de
	setanimation $02
	wait 20
	asm15 $76e6
	wait 8
	movenpcup $11
	movenpcleft $17
	jump2byte script7c07
script7c21:
	initcollisions
script7c22:
	checkabutton
	turntofacelink
	showloadedtext
	setanimation $00
	jump2byte script7c22
script7c29:
	asm15 $7700
	jumptable_memoryaddress $cfc1
	.dw script7c29
	.dw script7c33
script7c33:
	disableinput
	asm15 $76ec
	wait 30
	setspeed SPEED_100
	setangle $18
	asm15 $76f4
	wait 1
	movenpcup $20
	wait 30
	showtext $3430
	wait 30
	giveitem $4e00
	movenpcdown $80
	enableinput
	scriptend
script7c4e:
	initcollisions
	jumpifitemobtained $4e script7c56
	rungenericnpc $3431
script7c56:
	checkabutton
	disableinput
	showtext $3431
	wait 30
	asm15 $771a
	wait 60
	showtext $3432
	wait 30
	setstate $ff
	setspeed SPEED_200
	asm15 $770e
	jumptable_memoryaddress $cfc1
	.dw script7c72
	.dw script7c7b
script7c72:
	movenpcleft $18
	asm15 $7727
	movenpcup $30
	jump2byte script7c82
script7c7b:
	movenpcdown $10
	asm15 $772b
	movenpcright $40
script7c82:
	orroomflag $40
	enableinput
	scriptend
script7c86:
	setanimation $05
	setcollisionradii $08 $04
	makeabuttonsensitive
	checkabutton
	setdisabledobjectsto11
	setanimation $06
	wait 220
	showtext $3d05
	wait 60
	writememory wCutsceneTrigger $0f
	scriptend
script7c9b:
	loadscript scriptHlp.script15_775b
script7c9f:
	loadscript scriptHlp.script15_7781
script7ca3:
	loadscript scriptHlp.script15_7793
script7ca7:
	checkmemoryeq $cfd0 $01
	setanimation $03
	applyspeed $11
	checkmemoryeq $cfd0 $02
	setanimation $03
	checkmemoryeq $cfd0 $03
	setanimation $02
	checkmemoryeq $cfd0 $05
	setanimation $03
	checkmemoryeq $cfd0 $07
	writememory $d008 $01
	showtext $0607
	wait 30
	writememory $cfd0 $08
	wait 45
	writememory $d008 $01
	movenpcup $11
	writememory $d008 $00
	movenpcleft $11
	movenpcup $41
	scriptend
script7ce2:
	loadscript scriptHlp.script15_77b3
script7ce6:
	checkmemoryeq $cfd0 $01
	setspeed SPEED_100
	movenpcup $24
	movenpcleft $08
	setanimation $00
	writememory $cfd0 $02
	checkmemoryeq $cfd0 $03
	setanimation $01
	writememory $cfd0 $04
	checkmemoryeq $cfd0 $06
	setanimation $00
	checkmemoryeq $cfd0 $08
	movenpcup $38
	wait 30
	movenpcdown $08
	wait 30
	showtext $0608
	movenpcup $48
	enableinput
	scriptend
script7d17:
	checkcfc0bit 0
	asm15 $5854 $1e
	wait 120
	xorcfc0bit 1
	checkcfc0bit 5
	setspeed SPEED_080
	setangle $00
	applyspeed $31
	checkcfc0bit 6
	setanimation $03
	wait 15
	setanimation $01
	wait 15
	setanimation $02
	checkcfc0bit 7
	asm15 $5854 $1e
	scriptend
script7d34:
	loadscript scriptHlp.script15_77de
script7d38:
	checkabutton
	jumpifitemobtained $55 script7d41
	showtextlowindex $11
	jump2byte script7d38
script7d41:
	showtextlowindex $12
	jumpiftextoptioneq $01 script7d38
	orroomflag $40
	scriptend
script7d4a:
	showtext $2f27
	wait 4
	applyspeed $19
	wait 16
	orroomflag $40
	setmusic $ff
	scriptend
script7d57:
	setangle $10
	applyspeed $21
	wait 8
	showtext $2f28
	wait 8
	asm15 $77e6
	setangle $00
	applyspeed $21
	orroomflag $40
	scriptend
script7d6a:
	settileat $34 $01
	asm15 $c98 $70
	wait 30
	showtext $2f29
	wait 4
	applyspeed $11
	orroomflag $40
	scriptend
script7d7b:
	setspeed SPEED_080
	wait 180
script7d7e:
	setangle $18
	applyspeed $18
	wait 6
	setangle $08
	applyspeed $14
	wait 120
	jump2byte script7d7e
script7d8b:
	rungenericnpc $5711
script7d8e:
	jump2byte script7d8b
script7d90:
	wait 240
	setanimation $01
	wait 30
	showtext $5601
	wait 30
	setanimation $00
	wait 60
	writememory $cfd1 $02
	wait 180
	scriptend
script7da1:
	rungenericnpclowindex $0c
script7da3:
	rungenericnpclowindex $19
script7da5:
	rungenericnpclowindex $23
script7da7:
	loadscript scriptHlp.script15_78df
script7dab:
	loadscript scriptHlp.script15_7849
script7daf:
	rungenericnpclowindex $18
script7db1:
	jumpifglobalflagset $29 script7dbd
	rungenericnpclowindex $20
script7db7:
	jumpifglobalflagset $29 script7dbd
	rungenericnpclowindex $21
script7dbd:
	rungenericnpclowindex $22
script7dbf:
	rungenericnpclowindex $2c
script7dc1:
	loadscript scriptHlp.script15_7948
script7dc5:
	rungenericnpc $3608
script7dc8:
	rungenericnpc $3609
script7dcb:
	rungenericnpc $360a
script7dce:
	rungenericnpc $360b
script7dd1:
	initcollisions
	jumpifitemobtained $4f script7dd9
	rungenericnpc $360d
script7dd9:
	checkabutton
	disableinput
	playsound $f0
script7ddd:
	orroomflag $80
	spawninteraction $8006 $52 $6a
	playsound $6c
	wait 60
	playsound $b0
	shakescreen 160
	wait 120
	setcoords $58 $58
	asm15 $7972
	wait 60
	playsound $4d
	setmusic $ff
	asm15 loseTreasure $4f
	enableinput
	scriptend
script7dfd:
	enableinput
script7dfe:
	checkabutton
	jumpifitemobtained $54 script7e35
	jumpifglobalflagset $1b script7e0d
	setglobalflag $1b
	showtextnonexitablelowindex $00
	jump2byte script7e0f
script7e0d:
	showtextnonexitablelowindex $01
script7e0f:
	setdisabledobjectsto11
	jumptable_memoryaddress wSelectedTextOption
	.dw script7e1b
	.dw script7e17
script7e17:
	showtextlowindex $03
	jump2byte script7e49
script7e1b:
	disableinput
	showtextlowindex $02
	checktext
	giveitem $5400
	wait 1
	checktext
	showtextlowindex $04
	callscript script7ebc
	wait 60
	writememory $d103 $02
	setdisabledobjectsto11
	writememory $d104 $0a
	jump2byte script7dfe
script7e35:
	disableinput
	jumpifinteractionbyteeq $7e $00 script7e47
	jumptable_interactionbyte $7d
	.dw script7e50
	.dw script7e88
	.dw script7eae
script7e43:
	showtextlowindex $08
	jump2byte script7e49
script7e47:
	showtextlowindex $04
script7e49:
	checktext
	callscript script7ebc
	setdisabledobjectsto00
	jump2byte script7dfd
script7e50:
	jumpifglobalflagset $46 script7e43
	showtextnonexitablelowindex $06
	jumptable_memoryaddress wSelectedTextOption
	.dw script7e61
	.dw script7e5d
script7e5d:
	showtextlowindex $03
	jump2byte script7e49
script7e61:
	setglobalflag $46
	showtextlowindex $07
script7e65:
	writeinteractionbyte $7f $01
	setanimation $03
	showtextlowindex $0c
	checktext
script7e6d:
	jumpifinteractionbyteeq $7f $00 script7e75
	wait 1
	jump2byte script7e6d
script7e75:
	asm15 $7990
	wait 120
	giveitem $1904
	checktext
	asm15 refillSeedSatchel
	jumpifinteractionbyteeq $7d $02 script7eae
	setdisabledobjectsto00
	jump2byte script7dfd
script7e88:
	jumpifglobalflagset $14 script7e8e
	jump2byte script7e50
script7e8e:
	showtextlowindex $09
	jumptable_memoryaddress wSelectedTextOption
	.dw script7e9b
	.dw script7e97
script7e97:
	showtextlowindex $0a
	jump2byte script7e49
script7e9b:
	askforsecret $07
	wait 30
	jumpifmemoryeq $cc89 $00 script7ea8
	showtextlowindex $0d
	jump2byte script7e49
script7ea8:
	showtextlowindex $0e
	setglobalflag $6b
	jump2byte script7e65
script7eae:
	jumpifglobalflagset $14 script7eb4
	jump2byte script7e43
script7eb4:
	generatesecret $07
	setglobalflag $75
	showtextlowindex $0f
	jump2byte script7e49
script7ebc:
	writeinteractionbyte $7f $01
	setanimation $03
	showtextlowindex $05
	checktext
script7ec4:
	jumpifinteractionbyteeq $7f $00 script7ecc
	wait 1
	jump2byte script7ec4
script7ecc:
	retscript
script7ecd:
	showtext $0d09
	scriptend
script7ed1:
	loadscript scriptHlp.script15_79b2
script7ed5:
	loadscript scriptHlp.script15_7a38
script7ed9:
	asm15 $7a54
	jumpifmemoryset $cddb $80 stubScript
	initcollisions
	asm15 $7ab8
script7ee6:
	asm15 $7abd $00
	checkabutton
	disableinput
	showloadedtext
	wait 20
	jumpiftextoptioneq $00 script7ef9
	addinteractionbyte $72 $01
	showloadedtext
	enableinput
	jump2byte script7ee6
script7ef9:
	asm15 $7a8c
	jumpifmemoryset $cddb $80 script7f0c
script7f02:
	asm15 $7abd $02
	showloadedtext
	wait 20
	jumpiftextoptioneq $01 script7f02
script7f0c:
	asm15 $7aa2
	asm15 $7abd $03
script7f13:
	showloadedtext
	wait 20
	jumpiftextoptioneq $01 script7f13
	asm15 $7abd $04
	showloadedtext
	enableinput
	asm15 $7a8c
	jumpifmemoryset $cddb $80 script7ee6
	checkabutton
	disableinput
	jump2byte script7ef9
script7f2c:
	loadscript scriptHlp.script15_7acc
script7f30:
	asm15 $7a54
	jumpifmemoryset $cddb $80 stubScript
	asm15 objectSetInvisible
	writeinteractionbyte $7e $01
script7f3f:
	asm15 $7b14
	jumpifmemoryset $cddb $80 script7f4b
	wait 1
	jump2byte script7f3f
script7f4b:
	playsound $73
	createpuff
	wait 32
	setmusic $0f
	asm15 objectSetVisible
	writeinteractionbyte $7e $00
	jump2byte script7ed9
script7f5a:
	rungenericnpc $5111
script7f5d:
	asm15 $7b2f
	enableinput
	scriptend
script7f62:
	checkcfc0bit 0
	setmusic $f0
	wait 60
	asm15 $7b73
	wait 45
	asm15 $7bb1
	wait 60
	setmusic $ff
	playsound $4d
	enableinput
	scriptend
script7f75:
	setcollisionradii $08 $08
	makeabuttonsensitive
script7f79:
	checkabutton
	setdisabledobjectsto91
	cplinkx $48
	writeinteractionbyte $77 $01
	showloadedtext
	jumpiftextoptioneq $01 script7f8d
	wait 30
	addinteractionbyte $72 $0a
	showloadedtext
	addinteractionbyte $72 $f6
script7f8d:
	setdisabledobjectsto00
	writeinteractionbyte $77 $00
	jump2byte script7f79

