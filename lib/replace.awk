# Literal path replacement. Values arrive through the environment, never awk code.
{
  if (NR>1) printf "\n"
  rest=$0; needle=ENVIRON["AC_REPLACE_OLD"]; replacement=ENVIRON["AC_REPLACE_NEW"]
  while (needle!="" && (pos=index(rest,needle))>0) {
    printf "%s%s",substr(rest,1,pos-1),replacement
    rest=substr(rest,pos+length(needle))
  }
  printf "%s",rest
}
END { if (ENVIRON["AC_FINAL_NEWLINE"]=="1") printf "\n" }
