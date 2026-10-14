# Bounded Markdown selection and dependency inspection. No document rewriting.
BEGIN {
  mode=ENVIRON["AC_MARKDOWN_MODE"]; wanted=ENVIRON["AC_HEADING"]; offset=0; end=-1
  source=ENVIRON["AC_REFERENCE_SOURCE"]
  if (mode=="links" && source!="") {
    while ((getline original < source)>0) {
      sub(/^ */,"",original)
      if (original ~ /^\[[^]]+\]:/) {
        pos=index(original,"]:"); originaldefs[tolower(substr(original,2,pos-2))]=1
      }
    }
    close(source)
  }
}
function trim(s) { sub(/^[ \t]+/,"",s); sub(/[ \t]+$/,"",s); return s }
function anchor(s) { s=tolower(s); gsub(/[^[:alnum:]_ -]/,"",s); gsub(/ /,"-",s); return s }
function link(s) {
  s=trim(s)
  if (substr(s,1,1)=="<") { sub(/^</,"",s); sub(/>.*/,"",s) }
  else sub(/[ \t]+["\047].*/,"",s)
  if (s ~ /[ \t\\]/) bad=1
  links[s]=1
}
{
  raw=$0; line=raw; sub(/\r$/,"",line)
  nextoffset=offset+length(raw)+1
  match(line,/^ */); indent=RLENGTH
  text=substr(line,indent+1)
  if (indent<=3 && (substr(text,1,3)==sprintf("%c%c%c",96,96,96) || text ~ /^~~~/)) {
    character=substr(text,1,1); run=0
    while (substr(text,run+1,1)==character) run++
    if (!fenced) {
      if (character==sprintf("%c",96) && index(substr(text,run+1),character)) bad=1
      fenced=1; fencechar=character; fencelen=run
    }
    else if (character==fencechar && run>=fencelen && trim(substr(text,run+1))=="") fenced=0
    offset=nextoffset; next
  }
  if (fenced || indent>=4 || line ~ /^\t/) { offset=nextoffset; next }
  if (text ~ /^#+([ \t]|$)/) {
    match(text,/^#+/); level=RLENGTH
    if (level<=6) {
      title=trim(substr(text,level+1)); sub(/[ \t]+#+[ \t]*$/,"",title)
      headings[title]=1; anchors[anchor(title)]=1
      if (mode=="") {
        if (found && end<0 && level<=selectedlevel) end=offset
        if (title==wanted) { matches++; if (!found) { start=offset; selectedlevel=level; found=1 } }
      }
    }
  }
  if (mode=="ids" && text ~ /^#+([ \t]|$)/) {
    rest=text
    while (match(rest,/(DEC|IDEA|CON|Q)-[0-9]+/)) {
      ids[substr(rest,RSTART,RLENGTH)]=1; rest=substr(rest,RSTART+RLENGTH)
    }
  }
  if (mode=="links" || mode=="ids") {
    if (text ~ /^\[[^]]+\]:/) {
      pos=index(text,"]:")
      label=tolower(substr(text,2,pos-2)); value=trim(substr(text,pos+2))
      if (label ~ /^\^/) footnotes[label]=1
      else { if (label in definitions) bad=1; definitions[label]=value; link(value) }
    }
    rest=text
    while (match(rest,/\]\([^)]*\)/)) {
      link(substr(rest,RSTART+2,RLENGTH-3)); rest=substr(rest,RSTART+RLENGTH)
    }
    rest=text
    while (match(rest,/\[[^]]+\]\[[^]]*\]/)) {
      ref=substr(rest,RSTART,RLENGTH); closepos=index(ref,"]")
      label=substr(ref,closepos+2,length(ref)-closepos-2)
      if (label=="") label=substr(ref,2,closepos-2)
      references[tolower(label)]=1; rest=substr(rest,RSTART+RLENGTH)
    }
    rest=text
    while (match(rest,/\[\^[^]]+\]/)) {
      label=substr(rest,RSTART+1,RLENGTH-2)
      if (substr(rest,RSTART+RLENGTH,1)!=":") footnoteuses[tolower(label)]=1
      rest=substr(rest,RSTART+RLENGTH)
    }
    # Shortcut references count when the complete source defines their label.
    if (text !~ /^\[[^]]+\]:/) {
      rest=text
      gsub(/\[[^]]+\]\([^)]*\)/,"",rest)
      gsub(/\[[^]]+\]\[[^]]*\]/,"",rest)
      while (match(rest,/\[[^]]+\]/)) {
        label=tolower(substr(rest,RSTART+1,RLENGTH-2))
        if (label in originaldefs) references[label]=1
        rest=substr(rest,RSTART+RLENGTH)
      }
    }
  }
  offset=nextoffset
}
END {
  if (fenced) bad=1
  if (mode=="") {
    if (bad || matches!=1) exit 1
    if (end<0) end=offset
    print start,end
  } else if (mode=="ids") {
    for (title in headings) print "H " title
    for (title in headings) print "A " anchor(title)
    for (id in ids) print "I " id
    for (label in definitions) print "R " label
    for (label in footnotes) print "F " label
  } else if (mode=="links") {
    for (label in references) if (!(label in definitions)) bad=1
    for (label in footnoteuses) if (!(label in footnotes)) bad=1
    for (value in links) {
      if (substr(value,1,1)=="#" && !(substr(value,2) in anchors)) bad=1
      print value
    }
    if (bad) exit 1
  }
}
