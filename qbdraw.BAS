DEFINT A-Z

TYPE RegistersStr
 ax AS INTEGER
 cx AS INTEGER
 dx AS INTEGER
 bx AS INTEGER
END TYPE

CONST MAXPATH = 260
CONST PIXEL = 219

DECLARE FUNCTION Choice$ (x, y, Prompt AS STRING, Choices AS STRING)
DECLARE FUNCTION DetectMouse ()
DECLARE FUNCTION GetInput$ (x, y, Prompt AS STRING, WidthV, MaxLength, Filter AS STRING, Default AS STRING)
DECLARE FUNCTION LoadInt33h$ ()
DECLARE FUNCTION MouseStatus (x, y)
DECLARE SUB CallInt33h (Registers AS RegistersStr)
DECLARE SUB DisplayHelp ()
DECLARE SUB DisplayStatus (PixelX, PixelY, ColorV)
DECLARE SUB DrawBitmap (MouseX, MouseY)
DECLARE SUB Initialize ()
DECLARE SUB LoadBitmap (FileName AS STRING)
DECLARE SUB Main ()
DECLARE SUB Quit ()
DECLARE SUB SaveBitmap (FileName AS STRING)
DECLARE SUB SetMouseBorders (x1, y1, x2, y2)
DECLARE SUB SetPixel (MouseX, MouseY, ColorV)
DECLARE SUB ShowMouse ()
 
ON ERROR GOTO ErrorTrap
DIM SHARED Bitmap(0 TO 79, 0 TO 49) AS INTEGER

 Initialize
 CALL Main
 Quit
END

ErrorTrap:
 SELECT CASE Choice$(2, 2, "Error:" + STR$(ERR) + " - I = Ignore, Q = Quit", "IQiq")
  CASE "i", "i"
   RESUME NEXT
  CASE "q", "Q"
   END
 END SELECT

SUB CallInt33h (Registers AS RegistersStr)
STATIC Int33h AS STRING
 
 IF Int33h = "" THEN
  Int33h = LoadInt33h$
 END IF

 DEF SEG = VARSEG(Int33h)
 CALL ABSOLUTE(Registers, SADD(Int33h))
END SUB

FUNCTION Choice$ (x, y, Prompt AS STRING, Choices AS STRING)
DIM KeyStroke AS STRING

 LOCATE x, y
 PRINT Prompt;
 DO
  KeyStroke = INPUT$(1)
 LOOP UNTIL INSTR(Choices, KeyStroke) > 0
 LOCATE x, y
 PRINT SPACE$(LEN(Prompt));

 Choice$ = KeyStroke
END FUNCTION

FUNCTION DetectMouse
DIM Registers AS RegistersStr

 Registers.ax = 0
 CallInt33h Registers

 DetectMouse = Registers.ax
END FUNCTION

SUB DisplayHelp
 COLOR 15, 0
 CLS
 LOCATE 2, 2
 PRINT " QBDraw v1.00, by: Peter Swinkels - ***2025***"
 PRINT
 PRINT "  This program demonstrates how to implement the mouse in QBasic."
 PRINT
 PRINT "  Escape = Exit this program."
 PRINT "  F1     = Display this help."
 PRINT "  Tab    = Toggle the status bar on/off."
 PRINT "  L      = Load a drawing."
 PRINT "  N      = Start a new drawing."
 PRINT "  S      = Save a drawing."
 PRINT "  +/-    = Select one of 16 colors."
 PRINT
 PRINT "  Left mouse button  = Draw a pixel."
 PRINT "  Right mouse button = Erase a pixel."
 PRINT
 PRINT
 PRINT "  Press any key to exit this help..."

 DO
 LOOP WHILE INKEY$ = ""
END SUB

SUB DisplayStatus (PixelX, PixelY, ColorV)
 COLOR 15
 LOCATE 50, 1, 0
 PRINT USING " x: ##  y: ## c: "; PixelX; PixelY;
 PRINT USING "## = ["; ColorV;
 COLOR ColorV
 PRINT CHR$(PIXEL);
 COLOR 15
 PRINT "]   F1 = Help";
END SUB

SUB DrawBitmap (MouseX, MouseY)
DIM Registers AS RegistersStr

 Registers.ax = 0
 CallInt33h Registers

 FOR y = LBOUND(Bitmap, 2) TO UBOUND(Bitmap, 2)
  FOR x = LBOUND(Bitmap, 1) TO UBOUND(Bitmap, 1)
   COLOR Bitmap(x, y)
   LOCATE y + 1, x + 1
   PRINT CHR$(PIXEL);
  NEXT x
 NEXT y

 Registers.ax = 4
 Registers.cx = MouseX
 Registers.dx = MouseY
 CallInt33h Registers

 ShowMouse
END SUB

FUNCTION GetInput$ (x, y, Prompt AS STRING, WidthV, MaxLength, Filter AS STRING, Default AS STRING)
DIM DisplayedText AS STRING
DIM KeyStroke AS STRING
DIM Text AS STRING

 Text = Default
 DO
  Length = LEN(Text)
  LOCATE x, y
  IF LEN(Text) > WidthV THEN
   DisplayedText = RIGHT$(Text, WidthV)
  ELSE
   DisplayedText = Text
  END IF
  PRINT Prompt; " "; DisplayedText; " ";
  LOCATE x, y + LEN(Prompt + DisplayedText) + 1, 1
  DO
   KeyStroke = INKEY$
  LOOP WHILE KeyStroke = ""
  SELECT CASE KeyStroke
   CASE CHR$(8)
    IF Length > 0 THEN Text = LEFT$(Text, Length - 1)
   CASE CHR$(13)
    EXIT DO
   CASE CHR$(27)
    Text = ""
    EXIT DO
   CASE ELSE
    IF KeyStroke >= " " AND Length < MaxLength THEN
     Text = Text + KeyStroke
    END IF
  END SELECT
 LOOP

 LOCATE x, y, 0
 PRINT SPACE$(LEN(Prompt) + WidthV + 2)

 GetInput$ = Text
END FUNCTION

SUB Initialize
 IF DetectMouse THEN
  SCREEN 0
  WIDTH 80, 50
  COLOR 7, 0
  CLS
 ELSE
  PRINT "ERROR: No mouse detected!"
  SYSTEM
 END IF
END SUB

SUB LoadBitmap (FileName AS STRING)
DIM Buffer AS STRING

 FileH = FREEFILE
 OPEN FileName FOR INPUT LOCK READ WRITE AS FileH
  IF FREEFILE > FileH THEN
   CLOSE FileH

   FileH = FREEFILE
   OPEN FileName FOR BINARY LOCK READ WRITE AS FileH
    Buffer = INPUT$(LOF(FileH), FileH)
   CLOSE FileH

   FOR y = LBOUND(Bitmap, 2) TO UBOUND(Bitmap, 2)
    FOR x = LBOUND(Bitmap, 1) TO UBOUND(Bitmap, 1)
     Bitmap(x, y) = ASC(MID$(Buffer, (y * 80) + x + 1, 1))
    NEXT x
   NEXT y
  END IF
END SUB

FUNCTION LoadInt33h$
DIM FileH AS INTEGER
DIM Int33h AS STRING

 FileH = FREEFILE
 OPEN "Int33h.BIN" FOR INPUT LOCK READ WRITE AS FileH
 CLOSE FileH

 FileH = FREEFILE
 OPEN "Int33h.BIN" FOR BINARY LOCK READ WRITE AS FileH
  Int33h = INPUT$(LOF(FileH), FileH)
 CLOSE FileH

 LoadInt33h$ = Int33h
END FUNCTION

SUB Main
DIM FileName AS STRING
DIM KeyStroke AS STRING
DIM NewFileName AS STRING

 ShowMouse

 ColorV = 15
 StatusOn = -1

 DO
  DO
   IF StatusOn THEN DisplayStatus MouseX \ 8, MouseY \ 8, ColorV

   SELECT CASE MouseStatus(MouseX, MouseY)
    CASE 1
     SetPixel MouseX, MouseY, ColorV
    CASE 2
     SetPixel MouseX, MouseY, 0
   END SELECT

   KeyStroke = INKEY$
  LOOP WHILE KeyStroke = ""
  SELECT CASE KeyStroke
   CASE "+"
    IF ColorV = 15 THEN ColorV = 0 ELSE ColorV = ColorV + 1
   CASE "-"
    IF ColorV = 0 THEN ColorV = 15 ELSE ColorV = ColorV - 1
   CASE "l", "L"
    NewFileName = GetInput$(2, 2, "Load:", 70, MAXPATH, "*,/:?<>|" + CHR$(34), FileName)
    IF NOT NewFileName = "" THEN
     LoadBitmap NewFileName
     FileName = NewFileName
    END IF
    DrawBitmap MouseX, MouseY
   CASE "n", "N"
    IF UCASE$(Choice$(2, 2, "Start new drawing y/n?", "NYny")) = "Y" THEN
     ERASE Bitmap
    END IF
    DrawBitmap MouseX, MouseY
   CASE "s", "S"
    NewFileName = GetInput$(2, 2, "Save:", 70, MAXPATH, "*,/:?<>|" + CHR$(34), FileName)
    IF NOT NewFileName = "" THEN
     SaveBitmap NewFileName
     FileName = NewFileName
    END IF
    DrawBitmap MouseX, MouseY
   CASE CHR$(0) + ";"
    DisplayHelp
    DrawBitmap MouseX, MouseY
   CASE CHR$(9)
    CLS
    StatusOn = NOT StatusOn
    DrawBitmap MouseX, MouseY
   CASE CHR$(27)
    EXIT DO
  END SELECT
 LOOP
END SUB

FUNCTION MouseStatus (x, y)
DIM Registers AS RegistersStr

 Registers.ax = 3
 CallInt33h Registers
 
 x = Registers.cx
 y = Registers.dx
 MouseStatus = Registers.bx
END FUNCTION

SUB Quit
DIM Registers AS RegistersStr

 Registers.ax = 0
 CallInt33h Registers

 SCREEN 0
 WIDTH 80, 25
 COLOR 7, 0
 CLS
END SUB

SUB SaveBitmap (FileName AS STRING)
DIM Buffer AS STRING

 Buffer = ""
 FOR y = LBOUND(Bitmap, 2) TO UBOUND(Bitmap, 2)
  FOR x = LBOUND(Bitmap, 1) TO UBOUND(Bitmap, 1)
   Buffer = Buffer + CHR$(Bitmap(x, y))
  NEXT x
 NEXT y

 FileH = FREEFILE
 OPEN FileName FOR OUTPUT LOCK READ WRITE AS FileH
  PRINT #FileH, Buffer;
 CLOSE FileH
END SUB

SUB SetMouseBorders (x1, y1, x2, y2)
DIM Registers AS RegistersStr

 Registers.ax = 7
 Registers.cx = x1
 Registers.dx = x2
 CallInt33h Registers
 Registers.ax = 8
 Registers.cx = y1
 Registers.dx = y2
 CallInt33h Registers
END SUB

SUB SetPixel (MouseX, MouseY, ColorV)
DIM Registers AS RegistersStr
 
 Registers.ax = 0
 CallInt33h Registers

 PixelX = MouseX \ 8
 PixelY = MouseY \ 8
 Bitmap(PixelX, PixelY) = ColorV
 COLOR ColorV
 LOCATE PixelY + 1, PixelX + 1
 PRINT CHR$(PIXEL);

 Registers.ax = 4
 Registers.cx = MouseX
 Registers.dx = MouseY
 CallInt33h Registers

 ShowMouse
END SUB

SUB ShowMouse
DIM Registers AS RegistersStr

 Registers.ax = 1
 CallInt33h Registers

 SetMouseBorders 0, 0, 639, 399
END SUB

