{-# OPTIONS_GHC -w #-}
module HappyParser where

import Data.Char
import AST
import Lexer as L
import qualified Data.Array as Happy_Data_Array
import qualified Data.Bits as Bits
import Control.Applicative(Applicative(..))
import Control.Monad (ap)

-- parser produced by Happy Version 1.20.0

data HappyAbsSyn t4 t5 t6 t7 t8
	= HappyTerminal (Token)
	| HappyErrorToken Prelude.Int
	| HappyAbsSyn4 t4
	| HappyAbsSyn5 t5
	| HappyAbsSyn6 t6
	| HappyAbsSyn7 t7
	| HappyAbsSyn8 t8

happyExpList :: Happy_Data_Array.Array Prelude.Int Prelude.Int
happyExpList = Happy_Data_Array.listArray (0,179) ([37632,7170,192,1792,0,0,0,0,0,0,0,0,0,0,0,30720,1020,0,0,0,0,0,0,659,49180,164,12295,49193,1,0,30720,1021,0,0,10544,448,2636,112,659,49180,164,12295,49193,19457,28682,37632,7170,42176,1792,10544,448,2636,112,659,49180,164,32775,4039,57344,1009,30720,60,7680,15,1920,0,480,0,120,0,30,0,0,0,0,24576,0,6144,0,0,0,0
	])

{-# NOINLINE happyExpListPerState #-}
happyExpListPerState st =
    token_strs_expected
  where token_strs = ["error","%dummy","%start_calc","expression","literal","grouping","unary","binary","NUMBER","STRING","'='","'+'","'-'","'*'","'/'","'('","')'","'!'","'<'","'>'","'<='","'>='","'!='","'=='","'and'","'or'","'true'","'false'","'nil'","%eof"]
        bit_start = st Prelude.* 30
        bit_end = (st Prelude.+ 1) Prelude.* 30
        read_bit = readArrayBit happyExpList
        bits = Prelude.map read_bit [bit_start..bit_end Prelude.- 1]
        bits_indexed = Prelude.zip bits [0..29]
        token_strs_expected = Prelude.concatMap f bits_indexed
        f (Prelude.False, _) = []
        f (Prelude.True, nr) = [token_strs Prelude.!! nr]

action_0 (9) = happyShift action_3
action_0 (10) = happyShift action_4
action_0 (13) = happyShift action_12
action_0 (16) = happyShift action_13
action_0 (18) = happyShift action_14
action_0 (27) = happyShift action_5
action_0 (28) = happyShift action_6
action_0 (29) = happyShift action_7
action_0 (4) = happyGoto action_8
action_0 (5) = happyGoto action_2
action_0 (6) = happyGoto action_9
action_0 (7) = happyGoto action_10
action_0 (8) = happyGoto action_11
action_0 _ = happyFail (happyExpListPerState 0)

action_1 (9) = happyShift action_3
action_1 (10) = happyShift action_4
action_1 (27) = happyShift action_5
action_1 (28) = happyShift action_6
action_1 (29) = happyShift action_7
action_1 (5) = happyGoto action_2
action_1 _ = happyFail (happyExpListPerState 1)

action_2 _ = happyReduce_1

action_3 _ = happyReduce_5

action_4 _ = happyReduce_6

action_5 _ = happyReduce_7

action_6 _ = happyReduce_8

action_7 _ = happyReduce_9

action_8 (12) = happyShift action_18
action_8 (13) = happyShift action_19
action_8 (14) = happyShift action_20
action_8 (15) = happyShift action_21
action_8 (19) = happyShift action_22
action_8 (20) = happyShift action_23
action_8 (21) = happyShift action_24
action_8 (22) = happyShift action_25
action_8 (23) = happyShift action_26
action_8 (24) = happyShift action_27
action_8 (25) = happyShift action_28
action_8 (26) = happyShift action_29
action_8 (30) = happyAccept
action_8 _ = happyFail (happyExpListPerState 8)

action_9 _ = happyReduce_4

action_10 _ = happyReduce_2

action_11 _ = happyReduce_3

action_12 (9) = happyShift action_3
action_12 (10) = happyShift action_4
action_12 (13) = happyShift action_12
action_12 (16) = happyShift action_13
action_12 (18) = happyShift action_14
action_12 (27) = happyShift action_5
action_12 (28) = happyShift action_6
action_12 (29) = happyShift action_7
action_12 (4) = happyGoto action_17
action_12 (5) = happyGoto action_2
action_12 (6) = happyGoto action_9
action_12 (7) = happyGoto action_10
action_12 (8) = happyGoto action_11
action_12 _ = happyFail (happyExpListPerState 12)

action_13 (9) = happyShift action_3
action_13 (10) = happyShift action_4
action_13 (13) = happyShift action_12
action_13 (16) = happyShift action_13
action_13 (18) = happyShift action_14
action_13 (27) = happyShift action_5
action_13 (28) = happyShift action_6
action_13 (29) = happyShift action_7
action_13 (4) = happyGoto action_16
action_13 (5) = happyGoto action_2
action_13 (6) = happyGoto action_9
action_13 (7) = happyGoto action_10
action_13 (8) = happyGoto action_11
action_13 _ = happyFail (happyExpListPerState 13)

action_14 (9) = happyShift action_3
action_14 (10) = happyShift action_4
action_14 (13) = happyShift action_12
action_14 (16) = happyShift action_13
action_14 (18) = happyShift action_14
action_14 (27) = happyShift action_5
action_14 (28) = happyShift action_6
action_14 (29) = happyShift action_7
action_14 (4) = happyGoto action_15
action_14 (5) = happyGoto action_2
action_14 (6) = happyGoto action_9
action_14 (7) = happyGoto action_10
action_14 (8) = happyGoto action_11
action_14 _ = happyFail (happyExpListPerState 14)

action_15 _ = happyReduce_12

action_16 (12) = happyShift action_18
action_16 (13) = happyShift action_19
action_16 (14) = happyShift action_20
action_16 (15) = happyShift action_21
action_16 (17) = happyShift action_42
action_16 (19) = happyShift action_22
action_16 (20) = happyShift action_23
action_16 (21) = happyShift action_24
action_16 (22) = happyShift action_25
action_16 (23) = happyShift action_26
action_16 (24) = happyShift action_27
action_16 (25) = happyShift action_28
action_16 (26) = happyShift action_29
action_16 _ = happyFail (happyExpListPerState 16)

action_17 _ = happyReduce_11

action_18 (9) = happyShift action_3
action_18 (10) = happyShift action_4
action_18 (13) = happyShift action_12
action_18 (16) = happyShift action_13
action_18 (18) = happyShift action_14
action_18 (27) = happyShift action_5
action_18 (28) = happyShift action_6
action_18 (29) = happyShift action_7
action_18 (4) = happyGoto action_41
action_18 (5) = happyGoto action_2
action_18 (6) = happyGoto action_9
action_18 (7) = happyGoto action_10
action_18 (8) = happyGoto action_11
action_18 _ = happyFail (happyExpListPerState 18)

action_19 (9) = happyShift action_3
action_19 (10) = happyShift action_4
action_19 (13) = happyShift action_12
action_19 (16) = happyShift action_13
action_19 (18) = happyShift action_14
action_19 (27) = happyShift action_5
action_19 (28) = happyShift action_6
action_19 (29) = happyShift action_7
action_19 (4) = happyGoto action_40
action_19 (5) = happyGoto action_2
action_19 (6) = happyGoto action_9
action_19 (7) = happyGoto action_10
action_19 (8) = happyGoto action_11
action_19 _ = happyFail (happyExpListPerState 19)

action_20 (9) = happyShift action_3
action_20 (10) = happyShift action_4
action_20 (13) = happyShift action_12
action_20 (16) = happyShift action_13
action_20 (18) = happyShift action_14
action_20 (27) = happyShift action_5
action_20 (28) = happyShift action_6
action_20 (29) = happyShift action_7
action_20 (4) = happyGoto action_39
action_20 (5) = happyGoto action_2
action_20 (6) = happyGoto action_9
action_20 (7) = happyGoto action_10
action_20 (8) = happyGoto action_11
action_20 _ = happyFail (happyExpListPerState 20)

action_21 (9) = happyShift action_3
action_21 (10) = happyShift action_4
action_21 (13) = happyShift action_12
action_21 (16) = happyShift action_13
action_21 (18) = happyShift action_14
action_21 (27) = happyShift action_5
action_21 (28) = happyShift action_6
action_21 (29) = happyShift action_7
action_21 (4) = happyGoto action_38
action_21 (5) = happyGoto action_2
action_21 (6) = happyGoto action_9
action_21 (7) = happyGoto action_10
action_21 (8) = happyGoto action_11
action_21 _ = happyFail (happyExpListPerState 21)

action_22 (9) = happyShift action_3
action_22 (10) = happyShift action_4
action_22 (13) = happyShift action_12
action_22 (16) = happyShift action_13
action_22 (18) = happyShift action_14
action_22 (27) = happyShift action_5
action_22 (28) = happyShift action_6
action_22 (29) = happyShift action_7
action_22 (4) = happyGoto action_37
action_22 (5) = happyGoto action_2
action_22 (6) = happyGoto action_9
action_22 (7) = happyGoto action_10
action_22 (8) = happyGoto action_11
action_22 _ = happyFail (happyExpListPerState 22)

action_23 (9) = happyShift action_3
action_23 (10) = happyShift action_4
action_23 (13) = happyShift action_12
action_23 (16) = happyShift action_13
action_23 (18) = happyShift action_14
action_23 (27) = happyShift action_5
action_23 (28) = happyShift action_6
action_23 (29) = happyShift action_7
action_23 (4) = happyGoto action_36
action_23 (5) = happyGoto action_2
action_23 (6) = happyGoto action_9
action_23 (7) = happyGoto action_10
action_23 (8) = happyGoto action_11
action_23 _ = happyFail (happyExpListPerState 23)

action_24 (9) = happyShift action_3
action_24 (10) = happyShift action_4
action_24 (13) = happyShift action_12
action_24 (16) = happyShift action_13
action_24 (18) = happyShift action_14
action_24 (27) = happyShift action_5
action_24 (28) = happyShift action_6
action_24 (29) = happyShift action_7
action_24 (4) = happyGoto action_35
action_24 (5) = happyGoto action_2
action_24 (6) = happyGoto action_9
action_24 (7) = happyGoto action_10
action_24 (8) = happyGoto action_11
action_24 _ = happyFail (happyExpListPerState 24)

action_25 (9) = happyShift action_3
action_25 (10) = happyShift action_4
action_25 (13) = happyShift action_12
action_25 (16) = happyShift action_13
action_25 (18) = happyShift action_14
action_25 (27) = happyShift action_5
action_25 (28) = happyShift action_6
action_25 (29) = happyShift action_7
action_25 (4) = happyGoto action_34
action_25 (5) = happyGoto action_2
action_25 (6) = happyGoto action_9
action_25 (7) = happyGoto action_10
action_25 (8) = happyGoto action_11
action_25 _ = happyFail (happyExpListPerState 25)

action_26 (9) = happyShift action_3
action_26 (10) = happyShift action_4
action_26 (13) = happyShift action_12
action_26 (16) = happyShift action_13
action_26 (18) = happyShift action_14
action_26 (27) = happyShift action_5
action_26 (28) = happyShift action_6
action_26 (29) = happyShift action_7
action_26 (4) = happyGoto action_33
action_26 (5) = happyGoto action_2
action_26 (6) = happyGoto action_9
action_26 (7) = happyGoto action_10
action_26 (8) = happyGoto action_11
action_26 _ = happyFail (happyExpListPerState 26)

action_27 (9) = happyShift action_3
action_27 (10) = happyShift action_4
action_27 (13) = happyShift action_12
action_27 (16) = happyShift action_13
action_27 (18) = happyShift action_14
action_27 (27) = happyShift action_5
action_27 (28) = happyShift action_6
action_27 (29) = happyShift action_7
action_27 (4) = happyGoto action_32
action_27 (5) = happyGoto action_2
action_27 (6) = happyGoto action_9
action_27 (7) = happyGoto action_10
action_27 (8) = happyGoto action_11
action_27 _ = happyFail (happyExpListPerState 27)

action_28 (9) = happyShift action_3
action_28 (10) = happyShift action_4
action_28 (13) = happyShift action_12
action_28 (16) = happyShift action_13
action_28 (18) = happyShift action_14
action_28 (27) = happyShift action_5
action_28 (28) = happyShift action_6
action_28 (29) = happyShift action_7
action_28 (4) = happyGoto action_31
action_28 (5) = happyGoto action_2
action_28 (6) = happyGoto action_9
action_28 (7) = happyGoto action_10
action_28 (8) = happyGoto action_11
action_28 _ = happyFail (happyExpListPerState 28)

action_29 (9) = happyShift action_3
action_29 (10) = happyShift action_4
action_29 (13) = happyShift action_12
action_29 (16) = happyShift action_13
action_29 (18) = happyShift action_14
action_29 (27) = happyShift action_5
action_29 (28) = happyShift action_6
action_29 (29) = happyShift action_7
action_29 (4) = happyGoto action_30
action_29 (5) = happyGoto action_2
action_29 (6) = happyGoto action_9
action_29 (7) = happyGoto action_10
action_29 (8) = happyGoto action_11
action_29 _ = happyFail (happyExpListPerState 29)

action_30 (12) = happyShift action_18
action_30 (13) = happyShift action_19
action_30 (14) = happyShift action_20
action_30 (15) = happyShift action_21
action_30 (19) = happyShift action_22
action_30 (20) = happyShift action_23
action_30 (21) = happyShift action_24
action_30 (22) = happyShift action_25
action_30 (23) = happyShift action_26
action_30 (24) = happyShift action_27
action_30 _ = happyReduce_24

action_31 (12) = happyShift action_18
action_31 (13) = happyShift action_19
action_31 (14) = happyShift action_20
action_31 (15) = happyShift action_21
action_31 (19) = happyShift action_22
action_31 (20) = happyShift action_23
action_31 (21) = happyShift action_24
action_31 (22) = happyShift action_25
action_31 (23) = happyShift action_26
action_31 (24) = happyShift action_27
action_31 _ = happyReduce_23

action_32 (12) = happyShift action_18
action_32 (13) = happyShift action_19
action_32 (14) = happyShift action_20
action_32 (15) = happyShift action_21
action_32 (19) = happyShift action_22
action_32 (20) = happyShift action_23
action_32 (21) = happyShift action_24
action_32 (22) = happyShift action_25
action_32 _ = happyReduce_13

action_33 (12) = happyShift action_18
action_33 (13) = happyShift action_19
action_33 (14) = happyShift action_20
action_33 (15) = happyShift action_21
action_33 (19) = happyShift action_22
action_33 (20) = happyShift action_23
action_33 (21) = happyShift action_24
action_33 (22) = happyShift action_25
action_33 _ = happyReduce_14

action_34 (12) = happyShift action_18
action_34 (13) = happyShift action_19
action_34 (14) = happyShift action_20
action_34 (15) = happyShift action_21
action_34 _ = happyReduce_21

action_35 (12) = happyShift action_18
action_35 (13) = happyShift action_19
action_35 (14) = happyShift action_20
action_35 (15) = happyShift action_21
action_35 _ = happyReduce_22

action_36 (12) = happyShift action_18
action_36 (13) = happyShift action_19
action_36 (14) = happyShift action_20
action_36 (15) = happyShift action_21
action_36 _ = happyReduce_19

action_37 (12) = happyShift action_18
action_37 (13) = happyShift action_19
action_37 (14) = happyShift action_20
action_37 (15) = happyShift action_21
action_37 _ = happyReduce_20

action_38 _ = happyReduce_18

action_39 _ = happyReduce_17

action_40 (14) = happyShift action_20
action_40 (15) = happyShift action_21
action_40 _ = happyReduce_16

action_41 (14) = happyShift action_20
action_41 (15) = happyShift action_21
action_41 _ = happyReduce_15

action_42 _ = happyReduce_10

happyReduce_1 = happySpecReduce_1  4 happyReduction_1
happyReduction_1 (HappyAbsSyn5  happy_var_1)
	 =  HappyAbsSyn4
		 (EXP_LITERAL happy_var_1
	)
happyReduction_1 _  = notHappyAtAll 

happyReduce_2 = happySpecReduce_1  4 happyReduction_2
happyReduction_2 (HappyAbsSyn7  happy_var_1)
	 =  HappyAbsSyn4
		 (EXP_UNARY happy_var_1
	)
happyReduction_2 _  = notHappyAtAll 

happyReduce_3 = happySpecReduce_1  4 happyReduction_3
happyReduction_3 (HappyAbsSyn8  happy_var_1)
	 =  HappyAbsSyn4
		 (EXP_BINARY happy_var_1
	)
happyReduction_3 _  = notHappyAtAll 

happyReduce_4 = happySpecReduce_1  4 happyReduction_4
happyReduction_4 (HappyAbsSyn6  happy_var_1)
	 =  HappyAbsSyn4
		 (EXP_GROUPING happy_var_1
	)
happyReduction_4 _  = notHappyAtAll 

happyReduce_5 = happySpecReduce_1  5 happyReduction_5
happyReduction_5 (HappyTerminal (L.NUMBER happy_var_1))
	 =  HappyAbsSyn5
		 (AST.NUMBER happy_var_1
	)
happyReduction_5 _  = notHappyAtAll 

happyReduce_6 = happySpecReduce_1  5 happyReduction_6
happyReduction_6 (HappyTerminal (L.STRING happy_var_1))
	 =  HappyAbsSyn5
		 (AST.STRING happy_var_1
	)
happyReduction_6 _  = notHappyAtAll 

happyReduce_7 = happySpecReduce_1  5 happyReduction_7
happyReduction_7 _
	 =  HappyAbsSyn5
		 (AST.TRUE
	)

happyReduce_8 = happySpecReduce_1  5 happyReduction_8
happyReduction_8 _
	 =  HappyAbsSyn5
		 (AST.FALSE
	)

happyReduce_9 = happySpecReduce_1  5 happyReduction_9
happyReduction_9 _
	 =  HappyAbsSyn5
		 (AST.NIL
	)

happyReduce_10 = happySpecReduce_3  6 happyReduction_10
happyReduction_10 _
	(HappyAbsSyn4  happy_var_2)
	_
	 =  HappyAbsSyn6
		 (GROUP happy_var_2
	)
happyReduction_10 _ _ _  = notHappyAtAll 

happyReduce_11 = happySpecReduce_2  7 happyReduction_11
happyReduction_11 (HappyAbsSyn4  happy_var_2)
	_
	 =  HappyAbsSyn7
		 (UNARY_MINUS happy_var_2
	)
happyReduction_11 _ _  = notHappyAtAll 

happyReduce_12 = happySpecReduce_2  7 happyReduction_12
happyReduction_12 (HappyAbsSyn4  happy_var_2)
	_
	 =  HappyAbsSyn7
		 (UNARY_NEGATE happy_var_2
	)
happyReduction_12 _ _  = notHappyAtAll 

happyReduce_13 = happySpecReduce_3  8 happyReduction_13
happyReduction_13 (HappyAbsSyn4  happy_var_3)
	_
	(HappyAbsSyn4  happy_var_1)
	 =  HappyAbsSyn8
		 (BIN_EQ happy_var_1 happy_var_3
	)
happyReduction_13 _ _ _  = notHappyAtAll 

happyReduce_14 = happySpecReduce_3  8 happyReduction_14
happyReduction_14 (HappyAbsSyn4  happy_var_3)
	_
	(HappyAbsSyn4  happy_var_1)
	 =  HappyAbsSyn8
		 (BIN_NOT_EQ happy_var_1 happy_var_3
	)
happyReduction_14 _ _ _  = notHappyAtAll 

happyReduce_15 = happySpecReduce_3  8 happyReduction_15
happyReduction_15 (HappyAbsSyn4  happy_var_3)
	_
	(HappyAbsSyn4  happy_var_1)
	 =  HappyAbsSyn8
		 (BIN_ADD happy_var_1 happy_var_3
	)
happyReduction_15 _ _ _  = notHappyAtAll 

happyReduce_16 = happySpecReduce_3  8 happyReduction_16
happyReduction_16 (HappyAbsSyn4  happy_var_3)
	_
	(HappyAbsSyn4  happy_var_1)
	 =  HappyAbsSyn8
		 (BIN_SUB happy_var_1 happy_var_3
	)
happyReduction_16 _ _ _  = notHappyAtAll 

happyReduce_17 = happySpecReduce_3  8 happyReduction_17
happyReduction_17 (HappyAbsSyn4  happy_var_3)
	_
	(HappyAbsSyn4  happy_var_1)
	 =  HappyAbsSyn8
		 (BIN_MUL happy_var_1 happy_var_3
	)
happyReduction_17 _ _ _  = notHappyAtAll 

happyReduce_18 = happySpecReduce_3  8 happyReduction_18
happyReduction_18 (HappyAbsSyn4  happy_var_3)
	_
	(HappyAbsSyn4  happy_var_1)
	 =  HappyAbsSyn8
		 (BIN_DIV happy_var_1 happy_var_3
	)
happyReduction_18 _ _ _  = notHappyAtAll 

happyReduce_19 = happySpecReduce_3  8 happyReduction_19
happyReduction_19 (HappyAbsSyn4  happy_var_3)
	_
	(HappyAbsSyn4  happy_var_1)
	 =  HappyAbsSyn8
		 (BIN_COMP_GREATER happy_var_1 happy_var_3
	)
happyReduction_19 _ _ _  = notHappyAtAll 

happyReduce_20 = happySpecReduce_3  8 happyReduction_20
happyReduction_20 (HappyAbsSyn4  happy_var_3)
	_
	(HappyAbsSyn4  happy_var_1)
	 =  HappyAbsSyn8
		 (BIN_COMP_LESS happy_var_1 happy_var_3
	)
happyReduction_20 _ _ _  = notHappyAtAll 

happyReduce_21 = happySpecReduce_3  8 happyReduction_21
happyReduction_21 (HappyAbsSyn4  happy_var_3)
	_
	(HappyAbsSyn4  happy_var_1)
	 =  HappyAbsSyn8
		 (BIN_COMP_GREATER_EQ happy_var_1 happy_var_3
	)
happyReduction_21 _ _ _  = notHappyAtAll 

happyReduce_22 = happySpecReduce_3  8 happyReduction_22
happyReduction_22 (HappyAbsSyn4  happy_var_3)
	_
	(HappyAbsSyn4  happy_var_1)
	 =  HappyAbsSyn8
		 (BIN_COMP_LESS_EQ happy_var_1 happy_var_3
	)
happyReduction_22 _ _ _  = notHappyAtAll 

happyReduce_23 = happySpecReduce_3  8 happyReduction_23
happyReduction_23 (HappyAbsSyn4  happy_var_3)
	_
	(HappyAbsSyn4  happy_var_1)
	 =  HappyAbsSyn8
		 (BIN_AND happy_var_1 happy_var_3
	)
happyReduction_23 _ _ _  = notHappyAtAll 

happyReduce_24 = happySpecReduce_3  8 happyReduction_24
happyReduction_24 (HappyAbsSyn4  happy_var_3)
	_
	(HappyAbsSyn4  happy_var_1)
	 =  HappyAbsSyn8
		 (BIN_OR happy_var_1 happy_var_3
	)
happyReduction_24 _ _ _  = notHappyAtAll 

happyNewToken action sts stk [] =
	action 30 30 notHappyAtAll (HappyState action) sts stk []

happyNewToken action sts stk (tk:tks) =
	let cont i = action i i tk (HappyState action) sts stk tks in
	case tk of {
	L.NUMBER happy_dollar_dollar -> cont 9;
	L.STRING happy_dollar_dollar -> cont 10;
	L.EQUAL -> cont 11;
	L.PLUS -> cont 12;
	L.MINUS -> cont 13;
	L.STAR -> cont 14;
	L.SLASH -> cont 15;
	L.LEFT_PAREN -> cont 16;
	L.RIGHT_PAREN -> cont 17;
	L.BANG -> cont 18;
	L.LESS -> cont 19;
	L.GREATER -> cont 20;
	L.LESS_EQUAL -> cont 21;
	L.GREATER_EQUAL -> cont 22;
	L.BANG_EQUAL -> cont 23;
	L.EQUAL_EQUAL -> cont 24;
	L.AND -> cont 25;
	L.OR -> cont 26;
	L.TRUE -> cont 27;
	L.FALSE -> cont 28;
	L.NIL -> cont 29;
	_ -> happyError' ((tk:tks), [])
	}

happyError_ explist 30 tk tks = happyError' (tks, explist)
happyError_ explist _ tk tks = happyError' ((tk:tks), explist)

newtype HappyIdentity a = HappyIdentity a
happyIdentity = HappyIdentity
happyRunIdentity (HappyIdentity a) = a

instance Prelude.Functor HappyIdentity where
    fmap f (HappyIdentity a) = HappyIdentity (f a)

instance Applicative HappyIdentity where
    pure  = HappyIdentity
    (<*>) = ap
instance Prelude.Monad HappyIdentity where
    return = pure
    (HappyIdentity p) >>= q = q p

happyThen :: () => HappyIdentity a -> (a -> HappyIdentity b) -> HappyIdentity b
happyThen = (Prelude.>>=)
happyReturn :: () => a -> HappyIdentity a
happyReturn = (Prelude.return)
happyThen1 m k tks = (Prelude.>>=) m (\a -> k a tks)
happyReturn1 :: () => a -> b -> HappyIdentity a
happyReturn1 = \a tks -> (Prelude.return) a
happyError' :: () => ([(Token)], [Prelude.String]) -> HappyIdentity a
happyError' = HappyIdentity Prelude.. (\(tokens, _) -> parseError tokens)
calc tks = happyRunIdentity happySomeParser where
 happySomeParser = happyThen (happyParse action_0 tks) (\x -> case x of {HappyAbsSyn4 z -> happyReturn z; _other -> notHappyAtAll })

happySeq = happyDontSeq


parseError :: [Token] -> a
parseError _ = error "Parse error"


happyParser = calc . lexer
{-# LINE 1 "templates/GenericTemplate.hs" #-}
-- $Id: GenericTemplate.hs,v 1.26 2005/01/14 14:47:22 simonmar Exp $










































data Happy_IntList = HappyCons Prelude.Int Happy_IntList








































infixr 9 `HappyStk`
data HappyStk a = HappyStk a (HappyStk a)

-----------------------------------------------------------------------------
-- starting the parse

happyParse start_state = happyNewToken start_state notHappyAtAll notHappyAtAll

-----------------------------------------------------------------------------
-- Accepting the parse

-- If the current token is ERROR_TOK, it means we've just accepted a partial
-- parse (a %partial parser).  We must ignore the saved token on the top of
-- the stack in this case.
happyAccept (1) tk st sts (_ `HappyStk` ans `HappyStk` _) =
        happyReturn1 ans
happyAccept j tk st sts (HappyStk ans _) = 
         (happyReturn1 ans)

-----------------------------------------------------------------------------
-- Arrays only: do the next action









































indexShortOffAddr arr off = arr Happy_Data_Array.! off


{-# INLINE happyLt #-}
happyLt x y = (x Prelude.< y)






readArrayBit arr bit =
    Bits.testBit (indexShortOffAddr arr (bit `Prelude.div` 16)) (bit `Prelude.mod` 16)






-----------------------------------------------------------------------------
-- HappyState data type (not arrays)



newtype HappyState b c = HappyState
        (Prelude.Int ->                    -- token number
         Prelude.Int ->                    -- token number (yes, again)
         b ->                           -- token semantic value
         HappyState b c ->              -- current state
         [HappyState b c] ->            -- state stack
         c)



-----------------------------------------------------------------------------
-- Shifting a token

happyShift new_state (1) tk st sts stk@(x `HappyStk` _) =
     let i = (case x of { HappyErrorToken (i) -> i }) in
--     trace "shifting the error token" $
     new_state i i tk (HappyState (new_state)) ((st):(sts)) (stk)

happyShift new_state i tk st sts stk =
     happyNewToken new_state ((st):(sts)) ((HappyTerminal (tk))`HappyStk`stk)

-- happyReduce is specialised for the common cases.

happySpecReduce_0 i fn (1) tk st sts stk
     = happyFail [] (1) tk st sts stk
happySpecReduce_0 nt fn j tk st@((HappyState (action))) sts stk
     = action nt j tk st ((st):(sts)) (fn `HappyStk` stk)

happySpecReduce_1 i fn (1) tk st sts stk
     = happyFail [] (1) tk st sts stk
happySpecReduce_1 nt fn j tk _ sts@(((st@(HappyState (action))):(_))) (v1`HappyStk`stk')
     = let r = fn v1 in
       happySeq r (action nt j tk st sts (r `HappyStk` stk'))

happySpecReduce_2 i fn (1) tk st sts stk
     = happyFail [] (1) tk st sts stk
happySpecReduce_2 nt fn j tk _ ((_):(sts@(((st@(HappyState (action))):(_))))) (v1`HappyStk`v2`HappyStk`stk')
     = let r = fn v1 v2 in
       happySeq r (action nt j tk st sts (r `HappyStk` stk'))

happySpecReduce_3 i fn (1) tk st sts stk
     = happyFail [] (1) tk st sts stk
happySpecReduce_3 nt fn j tk _ ((_):(((_):(sts@(((st@(HappyState (action))):(_))))))) (v1`HappyStk`v2`HappyStk`v3`HappyStk`stk')
     = let r = fn v1 v2 v3 in
       happySeq r (action nt j tk st sts (r `HappyStk` stk'))

happyReduce k i fn (1) tk st sts stk
     = happyFail [] (1) tk st sts stk
happyReduce k nt fn j tk st sts stk
     = case happyDrop (k Prelude.- ((1) :: Prelude.Int)) sts of
         sts1@(((st1@(HappyState (action))):(_))) ->
                let r = fn stk in  -- it doesn't hurt to always seq here...
                happyDoSeq r (action nt j tk st1 sts1 r)

happyMonadReduce k nt fn (1) tk st sts stk
     = happyFail [] (1) tk st sts stk
happyMonadReduce k nt fn j tk st sts stk =
      case happyDrop k ((st):(sts)) of
        sts1@(((st1@(HappyState (action))):(_))) ->
          let drop_stk = happyDropStk k stk in
          happyThen1 (fn stk tk) (\r -> action nt j tk st1 sts1 (r `HappyStk` drop_stk))

happyMonad2Reduce k nt fn (1) tk st sts stk
     = happyFail [] (1) tk st sts stk
happyMonad2Reduce k nt fn j tk st sts stk =
      case happyDrop k ((st):(sts)) of
        sts1@(((st1@(HappyState (action))):(_))) ->
         let drop_stk = happyDropStk k stk





             _ = nt :: Prelude.Int
             new_state = action

          in
          happyThen1 (fn stk tk) (\r -> happyNewToken new_state sts1 (r `HappyStk` drop_stk))

happyDrop (0) l = l
happyDrop n ((_):(t)) = happyDrop (n Prelude.- ((1) :: Prelude.Int)) t

happyDropStk (0) l = l
happyDropStk n (x `HappyStk` xs) = happyDropStk (n Prelude.- ((1)::Prelude.Int)) xs

-----------------------------------------------------------------------------
-- Moving to a new state after a reduction









happyGoto action j tk st = action j j tk (HappyState action)


-----------------------------------------------------------------------------
-- Error recovery (ERROR_TOK is the error token)

-- parse error if we are in recovery and we fail again
happyFail explist (1) tk old_st _ stk@(x `HappyStk` _) =
     let i = (case x of { HappyErrorToken (i) -> i }) in
--      trace "failing" $ 
        happyError_ explist i tk

{-  We don't need state discarding for our restricted implementation of
    "error".  In fact, it can cause some bogus parses, so I've disabled it
    for now --SDM

-- discard a state
happyFail  ERROR_TOK tk old_st CONS(HAPPYSTATE(action),sts) 
                                                (saved_tok `HappyStk` _ `HappyStk` stk) =
--      trace ("discarding state, depth " ++ show (length stk))  $
        DO_ACTION(action,ERROR_TOK,tk,sts,(saved_tok`HappyStk`stk))
-}

-- Enter error recovery: generate an error token,
--                       save the old token and carry on.
happyFail explist i tk (HappyState (action)) sts stk =
--      trace "entering error recovery" $
        action (1) (1) tk (HappyState (action)) sts ((HappyErrorToken (i)) `HappyStk` stk)

-- Internal happy errors:

notHappyAtAll :: a
notHappyAtAll = Prelude.error "Internal Happy error\n"

-----------------------------------------------------------------------------
-- Hack to get the typechecker to accept our action functions







-----------------------------------------------------------------------------
-- Seq-ing.  If the --strict flag is given, then Happy emits 
--      happySeq = happyDoSeq
-- otherwise it emits
--      happySeq = happyDontSeq

happyDoSeq, happyDontSeq :: a -> b -> b
happyDoSeq   a b = a `Prelude.seq` b
happyDontSeq a b = b

-----------------------------------------------------------------------------
-- Don't inline any functions from the template.  GHC has a nasty habit
-- of deciding to inline happyGoto everywhere, which increases the size of
-- the generated parser quite a bit.









{-# NOINLINE happyShift #-}
{-# NOINLINE happySpecReduce_0 #-}
{-# NOINLINE happySpecReduce_1 #-}
{-# NOINLINE happySpecReduce_2 #-}
{-# NOINLINE happySpecReduce_3 #-}
{-# NOINLINE happyReduce #-}
{-# NOINLINE happyMonadReduce #-}
{-# NOINLINE happyGoto #-}
{-# NOINLINE happyFail #-}

-- end of Happy Template.
