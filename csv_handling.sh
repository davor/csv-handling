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
# @example get_row a.csv 2
get_row() {
  local FILE="$1"
  local ROW="$2"
  sed -n "$ROW"p < "$FILE"
}
#get_row a.csv 2

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

# Return field entry from csv_file
# @param1 path/to/csv_file.csv
# @param2 integer, colum number
# @param3 integer, row number
# @return field entry from csv_file
# @example get_field_entry a.csv 1 1 
get_field_entry() {
  local FILE="$1"
  local COLUMN="$2"
  local ROW="$3"
  get_row $FILE $ROW > get_field_entry_tmp_file.tmp
  get_column get_field_entry_tmp_file.tmp $COLUMN > get_field_entry_tmp_file2.tmp
  cat get_field_entry_tmp_file2.tmp
  rm get_field_entry_tmp_file*.tmp
}
#get_field_entry a.csv 1 1 

# Merge columns of different files and create new files for each column
# @param1 -f "path/to/csv_file_1.csv path/to/csv_file_2.csv ... path/to/csv_file_n.csv"
# @param2 -n "name1 name2 ... nameN"
# @param3 -t "title" will be used 
# @return  creates a file for each merged column 
# @example get_separated_columns -f "a.csv b.csv c.csv" -n "first,second,third" -t "test"
get_separated_columns() {
  
  local USAGE="usage: $0 -f \"path/to/csv_file_1.csv path/to/csv_file_2.csv ... path/to/csv_file_n.csv\" -n \"name1,name2,...,nameN\" -t \"title\""
  if [ $# != 6 ] 
  then
    echo "get_separated_columns requires three named arguments."
    echo $USAGE
    return 1
  fi

  local FILES=""
  local NR_FILES=""
  local METHODS=""
  local TITLE=""

  while [ "$1" != "" ]; do
    case $1 in
      -f)  shift
          FILES="$1"
          ;;
      -n)  shift
          METHODS="$1"
          ;;
      -t)  shift
          TITLE="$1"
          ;;
      ?)  echo "illegal option: $OPTARG" >&2
          echo $USAGE
          return 1
          ;;
      :) 
          echo "Option -$OPTARG requires an argument." >&2
          echo $USAGE
          return 1
          ;;
    esac
    shift
  done
  
  if [ "$TITLE" != "" ]
  then
    echo "The title is '$TITLE'. "
  else
    echo "Title has to be at least one character."
    echo $USAGE
    return 1
  fi
  
  NR_FILES=$(($(echo $METHODS | tr -cd ',' | wc -c)+1))

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
  mkdir -p "$TITLE"
  while [ "$cnt1" -le "$COLS" ] 
  do
    local cnt2="1"
    for f in $FILES
    do
      get_column "$f" "$cnt1" > get_separated_columns_tmp_file_"$cnt1"_"$cnt2".tmp
      cnt2="$(($cnt2+1))"
    done
    COLUMNTITLE=$(get_field_entry get_separated_columns_tmp_file_"$cnt1"_1.tmp 1 1)
    RESULTFILE="$TITLE"/"$TITLE"_"$COLUMNTITLE".csv
    merge_columns_file get_separated_columns_tmp_file_"$cnt1"_*.tmp > $RESULTFILE 
    sed -i 1d $RESULTFILE

    add_headline2file $RESULTFILE "$METHODS" 
    rm get_separated_columns_tmp_file_*.tmp
    cnt1="$(($cnt1+1))"
  done
  return 0
}
#get_separated_columns -f "a.csv b.csv c.csv" -n "first,second,third" -t "test"
#get_separated_columns -f "../exp3/bbrc_sample_KAZ_mle* ../exp3/bbrc_sample_KAZ_mean* ../exp3/bbrc_sample_KAZ_bbrc*" -n "MLE,MEAN,BBRC" -t "KAZ"
