/*********************************
** This long code reads and cleans FBI's Unified Crime Reporting files 
** Note, that the Macro runs with warnings and errors due to string values present in numeric fields.
** These strings represent non-number flags for invalid values. The dcumentation from FBI was incomeplte, so efforts 
** to clean these out of the data was aborted. The errors results in missing values and are ignorable. 
**
** Maintainer: Igor Holas, github.com/iholas
** Organization: UT Austin HDFS

	The macro returns a large number of variables reporting on the counts and rate of different offenses for different demografic groupings for "offense groups" Here I explain both.

	Based on available data, 2 grouping stategies are reported
	-- Gender by age
	-- Juvenile/Adult by race

	The variable names follow a naming convention


	==============
	Offense groups: 
	--------------
		1: 	Type 1 personal crimes
			Includes: 
				011 = Murder and Non-Negligent Manslaughter
				012 = Manslaughter by Negligence
				020 = Forcible Rape
				030 = Robbery
				040 = Aggravated Assault
				080 = Other Assaults

		2:	Type 1 property crimes
				050 = Burglary - Breaking or Entering
				060 = Larceny - Theft (except motor vehicle)
				070 = Motor Vehicle Theft
				090 = Arson

		3: 	Type 2 drug offenses
				18 = Drug Abuse Violations (Total)
					180 = Sale/Manufacturing (Subtotal)
						181 = Opium and Cocaine, and their derivatives
						(Morphine, Heroin)
						182 = Marijuana
						183 = Synthetic Narcotics - Manufactured
						Narcotics which can cause true drug addiction
						(Demerol, Methadones)
						184 = Other Dangerous Non-Narcotic Drugs
						(Barbiturates, Benzedrine)
					185 = Possession (Subtotal)
						186 = same as 181
						187 = same as 182
						188 = same as 183
						189 = same as 184

		4: Type 2 status offenses
				280 = Curfew and Loitering Law Violations
				290 = Runaways

		5: Type 2 other offenses
				100 = Forgery and Counterfeiting
				110 = Fraud
				120 = Embezzlement
				130 = Stolen property - Buying, Receiving, Poss.
				140 = Vandalism
				150 = Weapons - Carrying, Possessing, etc.
				160 = Prostitution and Commercialized Vice
				170 = Sex Offenses (except forcible rape and prostitution)
				19 = Gambling (Total)
					191 = Bookmaking (Horse and Sport Book)
					192 = Number and Lottery
					193 = All Other Gambling
				200 = Offenses Against Family and Children
				210 = Driving Under the Influence
				220 = Liquor Laws
				230 = Drunkenness
				240 = Disorderly Conduct
				250 = Vagrancy
				260 = All Other Offenses (except traffic)
				270 = Suspicion

	Age Groups:
	-----------
		Ju:	under 18
		18:	18 - 24
		25:	25 - 29
		30:	30+

	Variable names: 
	================
	2 Types: 
	-- by gender & age 
	-- by juv. status & race/eth. 

	Within each grouping "higher level" rgouping agrregates accross some of the groups (e.g. all women regardless of age), in this case, the variable denotes the ignored gruping level by underscores ('_'; example: M__1R94 is rate of males' personal crimes in 1994 regardless of age.

	By gender & age::
	------------------
	example: MJu1R
	M 	- gender [M | F] 
	Ju 	- age group [Ju (10 - 17) | 18 (18 - 24) | 25 (25 - 29) | 30 (30+)]
	1	- offese type  [1 | 2 | 3 | 4 | 5 - see above]
	R	- rate [R (rate) | C (count)]

	By juv. status & race/ethnicity
	---------------------------------
	example: JWh1C
	J	- status [J (juvenile) | A (adult)]
	Wh	- race ethnicity [Wh (White) | Bl (Black) | NA (Nat. Am.) | AA (API) | Hi (Latino) | NH (Not Latino)]
	1	- offese type  [1 | 2 | 3 | 4 | 5 - see above]
	R	- rate [R (rate) | C (count)]
	*/


** START MACRO **;
** REQUIRED:
** &ucr_filepath is a full parth and filename of the raw UCR data
** &out_data is the destination of the output SAS dataset
**;

%macro UCR_read (ucr_filepath=, out_data=);

****************************************
///////////////////\\\\\\\\\\\\\\\\\\\\\
	STEP 1: 
	Reaad in UCR data Headers
\\\\\\\\\\\\\\\\\\\/////////////////////
****************************************;

** Raw UCR data is complex with headers for Agency and for ech record
** These headers need to be read in separately from the record detail 

** The code below takes advantage of the Headers cosing the offense variable as 000
** We use this value to find headers and read them in seprately;

data ucr.header;
	infile &ucr_filepath
		LRECL = 564;

	length CC $ 1 agency $ 25 oricode $ 7;

	*checking whether agency header, or record;
	input  CC $ 40 Off 	23 - 25 @;

	retain oricode curpop;

	*if header, we proceed;
	if off = 000 then do;

		*set empty vars;
		oricode=' ';
		curpop=.;

		input
		/* Column 1 is skipped */
		state_n			 2-3   /*Numeric State Code. 
								Range is 01-62. Data records are in order by
								ORI code within numeric state code. The values are:
								50 = AK - Alaska
								01 = AL - Alabama
								03 = AR - Arkansas
								54 = AS - American Samoa
								02 = AZ - Arizona
								04 = CA - California
								05 = CO - Colorado
								06 = CT - Connecticut
								52 = CZ - Canal Zone
								08 = DC - District of Columbia
								07 = DE - Delaware
								09 = FL - Florida
								10 = GA- Georgia
								55 = GM - Guam
								51 = HI - Hawaii
								14 = IA - Iowa
								11 = ID - Idaho
								12 = IL - Illinois
								13 = IN - Indiana
								15 = KS - Kansas
								16 = KY - Kentucky
								17 = LA - Louisiana
								20 = MA - Massachusetts
								19 = MD - Maryland
								18 = ME - Maine
								21 = MI - Michigan
								22 = MN - Minnesota
								24 = MO - Missouri
								23 = MS - Mississippi
								25 = MT - Montana
								26 = NE - Nebraska
								32 = NC - North Carolina
								33 = ND - North Dakota
								28 = NH - New Hampshire
								29 = NJ - New Jersey
								30 = NM - New Mexico
								27 = NV - Nevada
								31 = NY - New York
								34 = OH - Ohio
								35 = OK - Oklahoma
								36 = OR - Oregon
								37 = PA - Pennsylvania
								53 = PR - Puerto Rico
								38 = RI - Rhode Island
								39 = SC - South Carolina
								40 = SD - South Dakota
								41 = TN - Tennessee
								42 = TX - Texas
								43 = UT - Utah
								62 = VI - Virgin Islands
								45 = VA - Virginia
								44 = VT - Vermont
								46 = WA - Washington
								48 = WI - Wisconsin
								47 = WV - West Virginia
								49 = WY - Wyoming*/
		ORICode	  $	  4-10     /*Originating Agency Identifier*/
		Group	  $	 11-12     /*Group 
								Group 0 is possessions; 
								1-7 are cities, 
								8-9 are counties.
								Sub-Group (position 12) is blank when not used. 
								All populations are inclusive. 
								Values are:
									0 = Possessions (Puerto Rico, Guam, Canal Zone, Virgin
									Islands, and American Samoa)
									1 = All cities 250,000 or over:
									1A= Cities 1,000,000 or over
									1B= Cities from 500,000 thru 999,999
									1C= Cities from 250,000 thru 499,999
									2 = Cities from 100,000 thru 249,000
									3 = Cities from 50,000 thru 99,000
									4 = Cities from 25,000 thru 49,999
									5 = Cities from 10,000 thru 24,999
									11 - 12 A2 Group (continued)
									6 = Cities from 2,500 thru 9,999
									7 = Cities under 2,500
									8 = Non-MSA Counties:
									8A= Non-MSA counties 100,000 or over
									8B= Non-MSA counties from 25,000 thru 99,999
									8C= Non-MSA counties from 10,000 thru 24,999
									8D= Non-MSA counties under 10,000
									8E= Non-MSA State Police
									9 = MSA Counties:
									9A= MSA counties 100,000 or over
									9B= MSA counties from 25,000 thru 99,999
									9C= MSA counties from 10,000 thru 24,999
									9D= MSA counties under 10,000
									9E= MSA State Police*/

		GeoDiv			13 	   /*Division. Geographic division in which the state is located 
								(from 1 thru 9). Possessions are coded "0". The states comprising 
								each division are as follows. The divisions are listed within region:
								POSESSIONS
								0 = Possessions
									54 American Samoa	52 Canal Zone	55 Guam	53 Puerto Rico	62 Virgin Islands
								REGION I - NORTHEAST
								1 = New England
	 								06 Connecticut	18 Maine	20 Massachusetts	28 New Hampshire	38 Rhode Island
									44 Vermont
								2 = Middle Atlantic
									29 New Jersey	31 New York	37 Pennsylvania	
								REGION II - NORTH CENTRAL
								3 = East North Central
									12 Illinois	13 Indiana	21 Michigan	34 Ohio	48 Wisconsin	
								4 = West North Central
									14 Iowa	15 Kansas	22 Minnesota	24 Missouri	26 Nebraska 33 North Dakota
									40 South Dakota
								REGION III - SOUTH
								5 = South Atlantic
									07 Delaware	08 District of Columbia 09 Florida 10 Georgia 19 Maryland 
									32 North Carolina 39 South Carolina	45 Virginia 47 West Virginia 
								6 = East South Central
									01 Alabama	16 Kentucky	23 Mississippi	41 Tennessee	
								7 = West South Central
									03 Arkansas	17 Louisiana	35 Oklahoma	42 Texas	
								REGION IV - WEST
								8 = Mountain
									02 Arizona	05 Colorado	11 Idaho	25 Montana	27 Nevada
									30 New Mexico	43 Utah	49 Wyoming
								9 = Pacific	
									50 Alaska	04 California	51 Hawaii	36 Oregon	46 Washington*/
		Year 		14 - 15 	  /*Year. Last two digits of the year the data reflects, 
									e.g., "85" =1985*/
		MSA			16-18		  /*MSA - 
									Metropolitan Statistical Area (MSA) number in which the
									city is located, if any. Blank if not used.*/
		Suburban	19				/*A "suburban" agency is an MSA city with less than
									50,000 population (groups 4 - 7) together with MSA counties
									(group 9).
									1 = Suburban
									0 = Non-Suburban*/
		/*20 Not Used.*/
		rep_j_a		21		  /* Report Indication.
									0 = Juvenile and Adult Reported
									1 = Juvenile Only Reported
									2 = Adult Only Reported
									3 = Not Reported*/
		rep_adj		22 			  /*Adjustment.
									0 = Age, Race, and Ethnic Origin Reported
									1 = No Age Reported
									2 = No Race Reported
									3 = No Ethnic Origin Reported
									4 = No Race or Ethnic Origin Reported
									5 = No Age or Ethnic Origin Reported
									6 = No Age or Race Reported*/
		/* 23 - 25 skipped*/
		city_n 28 - 32 			  /*Sequence Number. 
									A five-digit number which places all cities in
									alphabetic order, regardless of state. This field is blank for groups
									0, 8, and 9.*/
		County_n 33 - 35 			  /*County. Three-digit numeric code for the county in which the
									agency is located.*/
		/*36 - 39 A4 Not Used.*/
		CurPop	41 - 50 		  /*Current Population. Total population for the agency for the
									year reported.*/
		/*51 -109 A59 Not Used. NOTE: FBI uses positions 51 through 100 to store
					  	the first previous year's population through the fifth previous
					  	year's population.*/

		/*110 A1 Agency Count. Used to accumulate "agencies used" totals in
						various tabulations. This field is normally "1" but will be "0" for
						the U.S. Park Police and all State Police agencies whose ORI code
						ends in "SP" (or "99" in California).*/
		Agency	$ 111-135 		  /*Agency Name.*/
		State	$ 136-141 		  /*State Name*/
		/*142-564 A423 Not Used. NOTE: FBI uses positions 151 - 230 to store the
						populations from the sixth previous year's population through the
						thirteenth previous year's population.*/
	;

	if off = 000 then output ucr.header;
	end;
run;


****************************************
///////////////////\\\\\\\\\\\\\\\\\\\\\
	STEP 2: 
	Read UCR Recod detail
\\\\\\\\\\\\\\\\\\\/////////////////////
****************************************;
data ucr.detail;
	infile &ucr_filepath
		LRECL = 564;

	/*checking whether agency header, or record*/
	input  CC $ 40 Off 	23 - 25 @;
	retain oricode curpop;

	/*read in detail - output as a separate file*/
	if off NE 000 then do;
		drop CC;
		input
		/*1 skipped*/
		state_n			2-3   	/*state code*/
		ORICode	  $	  	4-10    /*Originating Agency Identifier*/
		Group	  $	 	11-12   /*Group*/
		GeoDiv			13 	   	/*Division.*/
		Year 			14 - 15 /*Year.*/
		MSA				16-18	/*MSA*/
	
		Card1_id  19  			/*Card 1 Indicator.
									0 = No Adult Male Reported
									1 = Adult Male Reported*/
		Card2_id  20 			/*Card 2 Indicator.
									0 = No Adult Female Reported
									1 = Adult Female Reported*/
		Card3_id  21 			/*Card 3 Indicator.
									0 = No Juvenile Reported
									1 = Juvenile Reported*/
		Adj		  22 			/*Adjustment.
									0 = Age, Race, and Ethnic Origin Reported
									1 = No Age Reported
									2 = No Race Reported
									3 = No Ethnic Origin Reported
									4 = No Race or Ethnic Origin Reported
									5 = No Age or Ethnic Origin Reported
									6 = No Age or Race Reported*/
		Off 	23 - 25 		/*Offense Code.
									000 = If "000", it is the HEADER record
									011 = Murder and Non-Negligent Manslaughter
									012 = Manslaughter by Negligence
									020 = Forcible Rape
									030 = Robbery
									040 = Aggravated Assault
									050 = Burglary - Breaking or Entering
									060 = Larceny - Theft (except motor vehicle)
									070 = Motor Vehicle Theft
									080 = Other Assaults
									090 = Arson
									100 = Forgery and Counterfeiting
									110 = Fraud
									120 = Embezzlement
									130 = Stolen property - Buying, Receiving, Poss.
									140 = Vandalism
									150 = Weapons - Carrying, Possessing, etc.
									160 = Prostitution and Commercialized Vice
									170 = Sex Offenses (except forcible rape and prostitution)
									18 = Drug Abuse Violations (Total)
									180 = Sale/Manufacturing (Subtotal)
									181 = Opium and Cocaine, and their derivatives
									(Morphine, Heroin)
									182 = Marijuana
									183 = Synthetic Narcotics - Manufactured
									Narcotics which can cause true drug addiction
									(Demerol, Methadones)
									184 = Other Dangerous Non-Narcotic Drugs
									(Barbiturates, Benzedrine)
									185 = Possession (Subtotal)
									186 = same as 181
									187 = same as 182
									188 = same as 183
									189 = same as 184
									19 = Gambling (Total)
									191 = Bookmaking (Horse and Sport Book)
									192 = Number and Lottery
									193 = All Other Gambling
									200 = Offenses Against Family and Children
									210 = Driving Under the Influence
									220 = Liquor Laws
									230 = Drunkenness
									240 = Disorderly Conduct
									250 = Vagrancy
									260 = All Other Offenses (except traffic)
									270 = Suspicion
									280 = Curfew and Loitering Law Violations
									290 = Runaways*/
		/*26 - 40 A15 Not Used. Set to blanks. FBI uses these positions for internal
						use as follows:
						26 - 30: Packed current population for 18 - 19 breakdowns for
						sorted and summarized tapes.
						31 - 34: Packed previous population as above.
						35 : Breakdown offenses for 18-19
						0 = No
						1 = Yes
						36 - 38: Packed agency count for 18-19
						DETAIL (continued)
						POSITION TYPE DESCRIPTION
						26 - 40 A15 Not Used. (continued)
						39 : Breakdown Offense - 18
						0 = No
						1 = Yes
						40 : Breakdown Offense - 19
						0 = No
						1 = Yes
		/*41 - 238 N198 Male Totals by Age.*/
		M_10	41 -49 			/*Under 10*/
		M_10_12	50 - 58 		/*10 -12*/
		M_13_14	59 - 67 		/*13 -14*/
		M_15	68 - 76 		/*15*/
		M_16	77 - 85 		/*16*/
		M_17	86 - 94 		/*17*/
		M_18	95 -103 		/*18*/
		M_19	104-112 		/*19*/
		M_20	113-121 		/*20*/
		M_21	122-130 		/*21*/
		M_22	131-139 		/*22*/
		M_23	140-148 		/*23*/
		M_24	149-157 		/*24*/
		M_25_29	158-166 		/*25 - 29*/
		M_30_34	167-175 		/*30 - 34*/
		M_35_39	176-184 		/*35 - 39*/
		M_40_44	185-193 		/*40 - 44*/
		M_45_49	194-202 		/*45 - 49*/
		M_50_54	203-211 		/*50 - 54*/
		M_55_59	212-220 		/*55 - 59*/
		M_60_64 221-229			/*60 - 64*/
		M_65_on	230-238 		/*Over 64*/

		/*239-436 N198 Female Totals by Age.*/
		F_10	239-247			/*Under 10*/
		F_10_12	248-256 		/*10 -12*/
		F_13_14	257-265 		/*13 -14*/
		F_15	266-274 		/*15*/
		F_16	275-283 		/*16*/
		F_17	284-292 		/*17*/
		F_18	293-301 		/*18*/
		F_19	302-310 		/*19*/
		F_20	311-319 		/*20*/
		F_21	320-328 		/*21*/
		F_22	329-337 		/*22*/
		F_23	338-346 		/*23*/
		F_24	347-355 		/*24*/
		F_25_29	356-364 		/*25 - 29*/
		F_30_34	365-373 		/*30 - 34*/
		F_35_39	374-382 		/*35 - 39*/
		F_40_44	383-391 		/*40 - 44*/
		F_45_49	392-400 		/*45 - 49*/
		F_50_54	401-409 		/*50 - 54*/
		F_55_59	410-418 		/*55 - 59*/
		F_60_64 419-427			/*60 - 64*/
		F_65_on	428-436 		/*Over 64*/

	/*437-490 N54 Juvenile Totals by Race and Ethnic Origin.*/
		J_White		437-445 		/*Juvenile - White*/
		J_Black		446-454 		/*Juvenile - Black*/
		J_NatAm		455-463			/*Juvenile - Indian*/
		J_AsiAm		464-472 		/*Juvenile - Asian*/
		J_Hisp		473-481 		/*Juvenile - Hispanic*/
		J_NotHis	482-490 		/*Juvenile - Non-Hispanic*/

	/*491-544 N54 Adult Totals by Race and Ethnic Origin.*/
		A_White		491-499 		/*Adult - White*/
		A_Black		500-508 		/*Adult - Black*/
		A_NatAm		509-517			/*Adult - Indian*/
		A_AsiAm		518-526 		/*Adult - Asian*/
		A_Hisp		527-535 		/*Adult - Hispanic*/
		A_NotHis	536-544 		/*Adult - Non-Hispanic*/
		;
	end;
	if off NE 000 then output ucr.detail;
	run;


****************************************
///////////////////\\\\\\\\\\\\\\\\\\\\\
	STEP 3: 
	Merge UCR header and detail
\\\\\\\\\\\\\\\\\\\/////////////////////
****************************************;

proc sort data=ucr.detail ; by oricode; 
proc sort data=ucr.header ; by oricode; 
run;

data d1;
	merge 	ucr.detail
			ucr.header (keep=oricode curpop);
	by oricode;
	run;


****************************************
///////////////////\\\\\\\\\\\\\\\\\\\\\
	STEP 4: 
	Clean and recode variables
\\\\\\\\\\\\\\\\\\\/////////////////////
****************************************;

data d2; 
	set d1;

	* count reported offense rates by group;
	MJu = sum (of M_10 M_10_12 M_13_14 M_15 M_16 M_17);
	M18 = sum (of M_18 M_19 M_20 M_21 M_22 M_23 M_24);
	M25 = M_25_29;
	M30 = sum (of M_30_34 M_35_39 M_40_44 M_45_49 M_50_54 M_55_59 M_60_64 M_65_on);

	FJu = sum (of F_10 F_10_12 F_13_14 F_15 F_16 F_17);
	F18 = sum (of F_18 F_19 F_20 F_21 F_22 F_23 F_24);
	F25 = F_25_29;
	F30 = sum (of F_30_34 F_35_39 F_40_44 F_45_49 F_50_54 F_55_59 F_60_64 F_65_on);

	* drop source vars;
	DROP 
		M_10	 	M_10_12		M_13_14		M_15		M_16		M_17		M_18	
		M_19	 	M_20		M_21		M_22		M_23		M_24		M_25_29	
		M_30_34	 	M_35_39		M_40_44		M_45_49		M_50_54		M_55_59		M_60_64 
		M_65_on	

		F_10		F_10_12		F_13_14		F_15		F_16		F_17		F_18	
		F_19	 	F_20  		F_21		F_22		F_23		F_24		F_25_29	
		F_30_34	 	F_35_39		F_40_44		F_45_49		F_50_54		F_55_59		F_60_64 
		F_65_on	;
	run;


****************************************
///////////////////\\\\\\\\\\\\\\\\\\\\\
	STEP 5: 
	Addressing that offense codes 
	18 (drugs) and 19(gambling) use 
	non-standard sub-codes
	OUTPUT FINAL DATA
\\\\\\\\\\\\\\\\\\\/////////////////////
****************************************;

proc sort data = d2 ; 
	by oricode off; 
	run;

data &out_data;
	set d2; 
	by oricode off;
	retain x1 x2;
	if first.oricode then do;
			x1=0;
			x2=0;
			end;

	if off not in (18, 19, 180 - 189, 190, 191, 192, 193) then output;

	else do; 
		if off = 18 then x1=1;	
		if off in (180, 185)and x1 NE 1 then x1=2; 
		if off in (180 - 189) and x1 = 1 then delete;
		if off in (181-184, 186-189) and x1=2 then delete;

		if off in (19, 190) then x2=1;
		if off in (191, 192, 193) and x2=1 then delete; 
		OUTPUT;	
		end;

	
	drop x1 x2;
	if state_n = . then delete;
	run;


****************************************
///////////////////\\\\\\\\\\\\\\\\\\\\\
	STEP 6: 
	Aggregate data by state
\\\\\\\\\\\\\\\\\\\/////////////////////
****************************************;

proc sort data=d3;
	by state_n off;
	run;


data d4;
	set d3;
	by state_n off;

	*Retain count variables to keep values between agency records;
	retain 
		MJu1C		M181C		M251C		M301C	M__1C	
		MJu2C		M182C		M252C		M302C	M__2C	
		MJu3C		M183C		M253C		M303C	M__3C	
		MJu4C		M184C		M254C		M304C	M__4C	
		MJu5C		M180C		M255C		M305C	M__5C	

		FJu1C		F181C		F251C		F301C 	F__1C	
		FJu2C		F182C		F252C		F302C	F__2C	
		FJu3C		F183C		F253C		F303C	F__3C	
		FJu4C		F184C		F254C		F304C	F__4C	
		FJu5C		F180C		F255C		F305C	F__5C

		_Ju1C		_181C		_251C		_301C 	_Ad1C		
		_Ju2C		_182C		_252C		_302C	_Ad2C
		_Ju3C		_183C		_253C		_303C	_Ad3C
		_Ju4C		_184C		_254C		_304C	_Ad4C
		_Ju5C		_180C		_255C		_305C	_Ad5C

	

		JWH1C		JBL1C		JNA1C		JAA1C		JHI1C		JNH1C	J__1C
		JWH2C		JBL2C		JNA2C		JAA2C		JHI2C		JNH2C	J__2C
		JWH3C		JBL3C		JNA3C		JAA3C		JHI3C		JNH3C	J__3C
		JWH4C		JBL4C		JNA4C		JAA4C		JHI4C		JNH4C	J__4C
		JWH5C		JBL5C		JNA5C		JAA5C		JHI5C		JNH5C	J__5C

		AWH1C		ABL1C		ANA1C		AAA1C		AHI1C		ANH1C	A__1C
		AWH2C		ABL2C		ANA2C		AAA2C		AHI2C		ANH2C	A__2C
		AWH3C		ABL3C		ANA3C		AAA3C		AHI3C		ANH3C	A__3C
		AWH4C		ABL4C		ANA4C		AAA4C		AHI4C		ANH4C	A__4C
		AWH5C		ABL5C		ANA5C		AAA5C		AHI5C		ANH5C	A__5C;

	

	* set arrays to aggregate from agencies to state;
	* NOTE: these are 2D arrays, array rows are offense categories;

	* male counts by age group;
	array MC (5,4)
		MJu1C		M181C		M251C		M301C	
		MJu2C		M182C		M252C		M302C	
		MJu3C		M183C		M253C		M303C	
		MJu4C		M184C		M254C		M304C	
		MJu5C		M180C		M255C		M305C;	

	* female counts by age group;
	array FC (5,4)
		FJu1C		F181C		F251C		F301C	
		FJu2C		F182C		F252C		F302C	
		FJu3C		F183C		F253C		F303C	
		FJu4C		F184C		F254C		F304C	
		FJu5C		F180C		F255C		F305C;	

	* higher-level female counts (ignore age);
	array F2 (5) 	F__1C
					F__2C
					F__3C
					F__4C
					F__5C;

	* higher-level male counts (ignore age);
	array M2 (5)	M__1C
					M__2C
					M__3C
					M__4C
					M__5C;

	* Juvenile counts (ignoring gender);
	array M3 (5,4) 	_Ju1C		_181C		_251C		_301C
					_Ju2C		_182C		_252C		_302C
					_Ju3C		_183C		_253C		_303C
					_Ju4C		_184C		_254C		_304C
					_Ju5C		_180C		_255C		_305C;

	* Adult counts (ignoring gender);
	array M4 (5)	_Ad1C
					_Ad2C
					_Ad3C
					_Ad4C
					_Ad5C;

	* Juvenile by Race counts;
	array JC (5,6)
		JWH1C		JBL1C		JNA1C		JAA1C		JHI1C		JNH1C
		JWH2C		JBL2C		JNA2C		JAA2C		JHI2C		JNH2C
		JWH3C		JBL3C		JNA3C		JAA3C		JHI3C		JNH3C
		JWH4C		JBL4C		JNA4C		JAA4C		JHI4C		JNH4C
		JWH5C		JBL5C		JNA5C		JAA5C		JHI5C		JNH5C;

	*Adult by race counts;
	array AC (5,6)
		AWH1C		ABL1C		ANA1C		AAA1C		AHI1C		ANH1C
		AWH2C		ABL2C		ANA2C		AAA2C		AHI2C		ANH2C
		AWH3C		ABL3C		ANA3C		AAA3C		AHI3C		ANH3C
		AWH4C		ABL4C		ANA4C		AAA4C		AHI4C		ANH4C
		AWH5C		ABL5C		ANA5C		AAA5C		AHI5C		ANH5C;

	*Juvenile counts (ignoring race) ;
	array j2 (5)	J__1C
					J__2C
					J__3C
					J__4C
					J__5C;

	* Adul counts (ignoring race);
	array a2 (5)	A__1C
					A__2C
					A__3C
					A__4C
					A__5C;

	*SOURCE ARRAYS;

	*offenses by males by age;	
	array orm (4)
		MJu M18 M25 M30;

	* offenses by females by age;
	array orf (4)
		FJu F18 F25 F30;

	*offense by juveniles by race;
	array orj (6)
		J_White		J_Black		J_NatAm		J_AsiAm		J_Hisp		J_NotHis;

	*offense by adults by race;
	array ora (6)
		A_White		A_Black		A_NatAm		A_AsiAm		A_Hisp		A_NotHis;

	* LET'S LOOP!

	*Set 0's at first record in state;
	if first.state_n then do;
		do i= 1 to 5;
			do j = 1 to 6;
				jc{i,j}=0;
				ac{i,j}=0;
				end;
			do j=1 to 4;
				mc{i,j}=0;
				fc{i,j}=0;
				m3 {i,j}=0;
				end;
			m2 {i} = 0;
			
			f2 {i}=0;
			m4 {i}= 0;
			a2 {i}= 0;
			j2 {i}= 0;
			end;
		end;

	* set offense group variable;
	if off in (11, 12, 20, 30, 40, 80) 	then offgrp=1;
		else if off in (50,60,70,90) 	then offgrp=2;
		else if off in (18,180,181,182,183,184,185,186,187,188,189) 	then offgrp=3;
		else if off in (280,290) 		then offgrp=4;
		else if off in (19,100,110,120,130,140,150,160,170,190,191,192,193,200,210,220,230,240,250,260,270) 	then offgrp=5;

	* Begin assigning values;
	* Based on offense goup and demographics, take reported offense count and assign to correct variable;
	if offgrp ne . then do;
		do i = 1 to 4;
			mc{offgrp,i} + orm{i};
			fc{offgrp,i} + orf{i};
			end;
		
		do i = 1 to 6;
			ac{offgrp,i} + ora{i};
			jc{offgrp,i} + orj{i};
			a2{offgrp}   + ac{offgrp,i};
			j2{offgrp}   + jc{offgrp,i};
			end;
		end;

	* clean at last record within state;
	* calculate higher-lelvel indices;
	if last.state_n then do;
		do j = 1 to 5;
			do i = 1 to 4;
				m2{j}	+ mc{j,i};
				f2{j}   + fc{j,i};
				m3{j,i} + mc{j,i};
				m3{j,i} + fc{j,i};
				if i>1 then do;
					m4{j} + mc{j,i};
					m4{j} + fc{j,i};
					end;
				end;
			
			do i = 1 to 6;
				a2{j}   + ac{j,i};
				j2{j}   + jc{j,i};
				end;
			end;

	*drop obsolete and helper vars;
	drop 	oricode 
			group	geodiv		msa	
			MJu M18 M25 M30
			FJu F18 F25 F30
			J_White		J_Black		J_NatAm		J_AsiAm		J_Hisp		J_NotHis
			A_White		A_Black		A_NatAm		A_AsiAm		A_Hisp		A_NotHis
			off curpop card1_id card2_id card3_id Adj i j offgrp;

		output;	
		end;
	run;

****************************************
///////////////////\\\\\\\\\\\\\\\\\\\\\
	STEP 7: 
	Get total population count per state
\\\\\\\\\\\\\\\\\\\/////////////////////
****************************************;
proc sort data=d3; by state_n oricode; run;
data d5 (keep=state_n pop); 
	set d3;	
	by state_n oricode;
	retain pop; 

	if first.state_n then pop=0;
	if first.oricode then pop+curpop;

	if last.state_n and last.oricode then output;
	run;



****************************************
///////////////////\\\\\\\\\\\\\\\\\\\\\
	STEP 8: 
	Merge state-level UCR info + population 
	Calculate offense rates
\\\\\\\\\\\\\\\\\\\/////////////////////
****************************************;
data out_data;
	merge d4 d5;
	by state_n;

	* Using census data to convert crime counts to crime rates per thousand;
	* Setting up arrays;

	*Original counts;
	array a1 	MJu1C		M181C		M251C		M301C	M__1C	
				MJu2C		M182C		M252C		M302C	M__2C	
				MJu3C		M183C		M253C		M303C	M__3C	
				MJu4C		M184C		M254C		M304C	M__4C	
				MJu5C		M180C		M255C		M305C	M__5C	

				FJu1C		F181C		F251C		F301C 	F__1C	
				FJu2C		F182C		F252C		F302C	F__2C	
				FJu3C		F183C		F253C		F303C	F__3C	
				FJu4C		F184C		F254C		F304C	F__4C	
				FJu5C		F180C		F255C		F305C	F__5C

				_Ju1C		_181C		_251C		_301C 	_Ad1C		
				_Ju2C		_182C		_252C		_302C	_Ad2C
				_Ju3C		_183C		_253C		_303C	_Ad3C
				_Ju4C		_184C		_254C		_304C	_Ad4C
				_Ju5C		_180C		_255C		_305C	_Ad5C	

				JWH1C		JBL1C		JNA1C		JAA1C		JHI1C		JNH1C	J__1C
				JWH2C		JBL2C		JNA2C		JAA2C		JHI2C		JNH2C	J__2C
				JWH3C		JBL3C		JNA3C		JAA3C		JHI3C		JNH3C	J__3C
				JWH4C		JBL4C		JNA4C		JAA4C		JHI4C		JNH4C	J__4C
				JWH5C		JBL5C		JNA5C		JAA5C		JHI5C		JNH5C	J__5C

				AWH1C		ABL1C		ANA1C		AAA1C		AHI1C		ANH1C	A__1C
				AWH2C		ABL2C		ANA2C		AAA2C		AHI2C		ANH2C	A__2C
				AWH3C		ABL3C		ANA3C		AAA3C		AHI3C		ANH3C	A__3C
				AWH4C		ABL4C		ANA4C		AAA4C		AHI4C		ANH4C	A__4C
				AWH5C		ABL5C		ANA5C		AAA5C		AHI5C		ANH5C	A__5C;

	*New variables -- rates;
	array a2 	MJu1R		M181R		M251R		M301R	M__1R	
				MJu2R		M182R		M252R		M302R	M__2R	
				MJu3R		M183R		M253R		M303R	M__3R	
				MJu4R		M184R		M254R		M304R	M__4R	
				MJu5R		M180R		M255R		M305R	M__5R	

				FJu1R		F181R		F251R		F301R 	F__1R	
				FJu2R		F182R		F252R		F302R	F__2R	
				FJu3R		F183R		F253R		F303R	F__3R	
				FJu4R		F184R		F254R		F304R	F__4R	
				FJu5R		F180R		F255R		F305R	F__5R	

				_Ju1R		_181R		_251R		_301R 	_Ad1R		
				_Ju2R		_182R		_252R		_302R	_Ad2R
				_Ju3R		_183R		_253R		_303R	_Ad3R
				_Ju4R		_184R		_254R		_304R	_Ad4R
				_Ju5R		_180R		_255R		_305R	_Ad5R	

				JWH1R		JBL1R		JNA1R		JAA1R		JHI1R		JNH1R	J__1R
				JWH2R		JBL2R		JNA2R		JAA2R		JHI2R		JNH2R	J__2R
				JWH3R		JBL3R		JNA3R		JAA3R		JHI3R		JNH3R	J__3R
				JWH4R		JBL4R		JNA4R		JAA4R		JHI4R		JNH4R	J__4R
				JWH5R		JBL5R		JNA5R		JAA5R		JHI5R		JNH5R	J__5R

				AWH1R		ABL1R		ANA1R		AAA1R		AHI1R		ANH1R	A__1R
				AWH2R		ABL2R		ANA2R		AAA2R		AHI2R		ANH2R	A__2R
				AWH3R		ABL3R		ANA3R		AAA3R		AHI3R		ANH3R	A__3R
				AWH4R		ABL4R		ANA4R		AAA4R		AHI4R		ANH4R	A__4R
				AWH5R		ABL5R		ANA5R		AAA5R		AHI5R		ANH5R	A__5R;

	*Original variables -- counts for juveniles;
	array a3 	_Ju1C		
				_Ju2C		
				_Ju3C		
				_Ju4C		
				_Ju5C		

				JWH1C		JBL1C		JNA1C		JAA1C		JHI1C		JNH1C	J__1C
				JWH2C		JBL2C		JNA2C		JAA2C		JHI2C		JNH2C	J__2C
				JWH3C		JBL3C		JNA3C		JAA3C		JHI3C		JNH3C	J__3C
				JWH4C		JBL4C		JNA4C		JAA4C		JHI4C		JNH4C	J__4C
				JWH5C		JBL5C		JNA5C		JAA5C		JHI5C		JNH5C	J__5C;
	
	*New variables - rates for juveniles;
	array a4 	_Ju1R		
				_Ju2R		
				_Ju3R		
				_Ju4R		
				_Ju5R		

				JWH1R		JBL1R		JNA1R		JAA1R		JHI1R		JNH1RC	J__1R
				JWH2R		JBL2R		JNA2R		JAA2R		JHI2R		JNH2RC	J__2R
				JWH3R		JBL3R		JNA3R		JAA3R		JHI3R		JNH3RC	J__3R
				JWH4R		JBL4R		JNA4R		JAA4R		JHI4R		JNH4RC	J__4R
				JWH5R		JBL5R		JNA5RC		JAA5R		JHI5RC		JNH5RC	J__5R;
	
	*no need for 2D array, so just running straight through;
	do i = 1 to 145;

		* Dividing by popuation of 1000;
		a2{i} = a1{i} / (pop/1000);
		
		*Calculating juvenile rates dividing by population. 
		* Dividing by populatin of children would be betted, but that value is not available;
		if i < 41 then a4{i} = a3{i} / (pop/1000);

		end;

	*cleaning up;
	if state_n = . then delete;
	drop i;
	run;

*end macro;	
%mend UCR_read;
