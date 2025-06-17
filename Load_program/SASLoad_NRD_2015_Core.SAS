/*****************************************************************************
 * SASload_NRD_2015_Core.SAS
 * Created on 10/31/2017.
 * This program will load the NRD_2015_Core CSV File into SAS.
 *****************************************************************************/

/* Create SAS informats for missing values */
PROC FORMAT;
  INVALUE N2PF
    '-9' = .
    '-8' = .A
    '-6' = .C
    '-5' = .N
    OTHER = (|2.|)
  ;
  INVALUE N3PF
    '-99' = .
    '-88' = .A
    '-66' = .C
    OTHER = (|3.|)
  ;
  INVALUE N4PF
    '-999' = .
    '-888' = .A
    '-666' = .C
    OTHER = (|4.|)
  ;
  INVALUE N4P1F
    '-9.9' = .
    '-8.8' = .A
    '-6.6' = .C
    OTHER = (|4.1|)
  ;
  INVALUE N5PF
    '-9999' = .
    '-8888' = .A
    '-6666' = .C
    OTHER = (|5.|)
  ;
  INVALUE N5P2F
    '-9.99' = .
    '-8.88' = .A
    '-6.66' = .C
    OTHER = (|5.2|)
  ;
  INVALUE N6PF
    '-99999' = .
    '-88888' = .A
    '-66666' = .C
    OTHER = (|6.|)
  ;
  INVALUE N6P2F
    '-99.99' = .
    '-88.88' = .A
    '-66.66' = .C
    OTHER = (|6.2|)
  ;
  INVALUE N7P2F
    '-999.99' = .
    '-888.88' = .A
    '-666.66' = .C
    OTHER = (|7.2|)
  ;
  INVALUE N8PF
    '-9999999' = .
    '-8888888' = .A
    '-6666666' = .C
    OTHER = (|8.|)
  ;
  INVALUE N8P2F
    '-9999.99' = .
    '-8888.88' = .A
    '-6666.66' = .C
    OTHER = (|8.2|)
  ;
  INVALUE N8P4F
    '-99.9999' = .
    '-88.8888' = .A
    '-66.6666' = .C
    OTHER = (|8.4|)
  ;
  INVALUE N10PF
    '-999999999' = .
    '-888888888' = .A
    '-666666666' = .C
    OTHER = (|10.|)
  ;
  INVALUE N10P4F
    '-9999.9999' = .
    '-8888.8888' = .A
    '-6666.6666' = .C
    OTHER = (|10.4|)
  ;
  INVALUE N10P5F
    '-999.99999' = .
    '-888.88888' = .A
    '-666.66666' = .C
    OTHER = (|10.5|)
  ;
  INVALUE DATE10F
    '-999999999' = .
    '-888888888' = .A
    '-666666666' = .C
    OTHER = (|MMDDYY10.|)
  ;
  INVALUE N11P7F
    '-99.9999999' = .
    '-88.8888888' = .A
    '-66.6666666' = .C
    OTHER = (|11.7|)
  ;
  INVALUE N12P2F
    '-99999999.99' = .
    '-88888888.88' = .A
    '-66666666.66' = .C
    OTHER = (|12.2|)
  ;
  INVALUE N12P5F
    '-99999.99999' = .
    '-88888.88888' = .A
    '-66666.66666' = .C
    OTHER = (|12.5|)
  ;
  INVALUE N13PF
    '-999999999999' = .
    '-888888888888' = .A
    '-666666666666' = .C
    OTHER = (|13.|)
  ;
  INVALUE N15P2F
    '-99999999999.99' = .
    '-88888888888.88' = .A
    '-66666666666.66' = .C
    OTHER = (|15.2|)
  ;
RUN;

/* Data Step to load the file */
DATA NRD_2015_Core; 
INFILE 'cc2015NRD.csv' dsd dlm=',' LRECL = 128;

/* Define data element attributes */
ATTRIB 
  AGE                        LENGTH=3
  LABEL="Age in years at admission"

  AWEEKEND                   LENGTH=3
  LABEL="Admission day is a weekend"

  DIED                       LENGTH=3
  LABEL="Died during hospitalization"

  DISCWT                     LENGTH=8
  LABEL="Weight to discharges in AHA universe"

  DISPUNIFORM                LENGTH=3
  LABEL="Disposition of patient (uniform)"

  DMONTH                     LENGTH=3
  LABEL="Discharge month"

  DQTR                       LENGTH=3
  LABEL="Discharge quarter"

  ELECTIVE                   LENGTH=3
  LABEL="Elective versus non-elective admission"

  FEMALE                     LENGTH=3
  LABEL="Indicator of sex"

  HCUP_ED                    LENGTH=3
  LABEL="HCUP Emergency Department service indicator"

  HOSP_NRD                   LENGTH=4
  LABEL="NRD hospital identifier"

  KEY_NRD                    LENGTH=8
  LABEL="NRD record identifier"

  LOS                        LENGTH=4
  LABEL="Length of stay (cleaned)"

  NRD_DaysToEvent            LENGTH=8
  LABEL="Timing variable used to identify days between admissions"

  NRD_STRATUM                LENGTH=3
  LABEL="NRD stratum used for weighting"

  NRD_VisitLink              LENGTH=$7
  LABEL="NRD visitlink"

  PAY1                       LENGTH=3
  LABEL="Primary expected payer (uniform)"

  PL_NCHS                    LENGTH=3
  LABEL="Patient Location: NCHS Urban-Rural Code"

  REHABTRANSFER              LENGTH=3
  LABEL="A combined record involving rehab transfer"

  RESIDENT                   LENGTH=3
  LABEL="Patient State is the same as Hospital State"

  SAMEDAYEVENT               LENGTH=$2
  LABEL="Transfer flag indicating combination of discharges involve same day events"

  TOTCHG                     LENGTH=6
  LABEL="Total charges (cleaned)"

  YEAR                       LENGTH=3
  LABEL="Calendar year"

  ZIPINC_QRTL                LENGTH=3
  LABEL="Median household income national quartile for patient ZIP Code"
  ;

/* Read data elements from the CSV file */
INPUT 
      AGE                      :N3PF.
      AWEEKEND                 :N2PF.
      DIED                     :N2PF.
      DISCWT                   :N11P7F.
      DISPUNIFORM              :N2PF.
      DMONTH                   :N2PF.
      DQTR                     :N2PF.
      ELECTIVE                 :N2PF.
      FEMALE                   :N2PF.
      HCUP_ED                  :N2PF.
      HOSP_NRD                 :5.
      KEY_NRD                  :15.
      LOS                      :N5PF.
      NRD_DaysToEvent          :N10PF.
      NRD_STRATUM              :N5PF.
      NRD_VisitLink            :$CHAR7.
      PAY1                     :N2PF.
      PL_NCHS                  :N3PF.
      REHABTRANSFER            :N2PF.
      RESIDENT                 :N2PF.
      SAMEDAYEVENT             :$CHAR2.
      TOTCHG                   :N10PF.
      YEAR                     :N4PF.
      ZIPINC_QRTL              :N2PF.
      ;
RUN;
