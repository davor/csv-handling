#!/bin/sh
# CSV handling
# David Vorgrimmler

# Returns n-th column of file
# @param1 path/to/csv_file.csv
# @param2 integer(,integer,...,integer) (column number(s))
# @return column x from csv_file
# @example get_column a.csv 1
get_column() {
  local FILE="$1"
  local COLUMN="$2"
  cut -d, -f"$COLUMN" < "$FILE"
}
#get_column a.csv 1


# Returns n-th row of file 
# @param1 path/to/csv_file.csv
# @param2 integer (row number)
# @return row x from csv_file
# @example get_row a.csv 1
get_row() {
  local FILE="$1"
  local ROW="$2"
  sed -n "$ROW"p < "$FILE"
}
#get_row a.csv 1

# Merge files (attach first line file1 with first line file2 ...)
# @param1 path/to/csv_file_1.csv
# @param2 path/to/csv_file_2.csv
# @paramN path/to/csv_file_N.csv
# @return merged columns from all files 
# @example merge_columns_file a.csv b.csv
merge_columns_file() {
  local FILES="$*"
  paste -d , $FILES
}
#merge_columns_file a.csv b.csv

# Displays number of columns for file with n X m columns
# @param1 path/to/csv_file_1.csv
# @param2 separator (e.g. ",")
# @return Sets variable $COLCNT to number of columns 
# @example colcnt a.csv "," ; echo $COLCNT
colcnt() {
  local FILE="$1";
  local DELIM="$2";
  COLCNT=`awk -F"$DELIM" '{print NF}' "$FILE" | uniq`
  if [ $? -eq 0 ] ; then
    local TESTCOLCNT="`echo $COLCNT | tr -d ' '`"
    if [ "${#COLCNT}" -gt 0 ] && [ "$TESTCOLCNT" -gt 0 ] ; then
      if [ "$TESTCOLCNT" -eq "$COLCNT" ] ; then
        return 0
      else
        echo "colcnt failed. Different number of column per row in file: $FILE"
        return 1
      fi
    else
      echo "colcnt failed. File($FILE) is empty."
      return 1
    fi
  else
    echo "colcnt failed for file: $FILE"
    return 1
  fi
}
#colcnt a.csv "," ; echo $COLCNT

# Add headline(string) to file
# @param1 path/to/csv_file.csv
# @param2 String
# @return Inserts String at top of csv_file
# @example add_headline2file abcd.txt bla,bla,blub 
add_headline2file() {
  local FILE="$1"
  local HL="$2"
  echo "$FILE"
  echo "$HL" > "$FILE".tmp
  cat "$FILE" >> "$FILE".tmp
  mv "$FILE".tmp "$FILE"
}
#add_headline2file abcd.txt bla,bla,blub 


# Merge columns of different files and create new files for each column
# @param1 path/to/csv_file_1.csv
# @param2 path/to/csv_file_2.csv
# @paramN path/to/csv_file_N.csv
# @return  creates a file for each merged column 
# @example get_separated_columns a.csv b.csv c.csv
get_separated_columns() {
  local FILES="$*"
  local NR_FILES="$#"
  local COLS="0"
  for F in $FILES  
  do
    colcnt "$F" ","
    if [ "$?" -eq 0 ] ; then
      if [ "$COLS" -eq 0 ] ; then
        COLS="$COLCNT"
      else
        if [ "$COLS" -eq "$COLCNT" ] ; then
          echo "Same number of columns"
        else
          echo "Input ERROR: get_separated_columns failed. Files have not the same number of columns: $F"
          return 1
        fi
      fi
    else
      return 1
    fi
  done
  local cnt1="1"
  while [ "$cnt1" -le "$COLS" ] 
  do
    local cnt2="1"
    for f in $FILES
    do
      get_column "$f" "$cnt1" > get_separated_columns_tmp_file_"$cnt1"_"$cnt2".tmp
      cnt2="$(($cnt2+1))"
    done
    NAME=""
    #NAME="KAZ_"
    merge_columns_file get_separated_columns_tmp_file_"$cnt1"_*.tmp > "$NAME"column_"$cnt1"_merged.csv
    #add_headline2file "$NAME"column_"$cnt1"_merged.csv MLE,MEAN,BBRC
    rm get_separated_columns_tmp_file_*.tmp
    cnt1="$(($cnt1+1))"
  done
}
#get_separated_columns a.csv b.csv c.csv
#get_separated_columns ../exp3/bbrc_sample_KAZ*

