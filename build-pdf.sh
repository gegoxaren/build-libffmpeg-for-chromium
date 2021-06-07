#/usr/bin/env bash
FALSE=0
TRUE=1

_IGNORE_PANDOC_CROSSREF=${FALSE}
_FOUND_PANDOC=${FALSE}
_FOUND_PANDOC_CROSSREF=${FALSE}
_FOUND_XDG=${FALSE}

_PDF_NAME=libffmpeg_from_source
_MD_NAME=document

___help___ () {
  echo ""
  echo "    Build script for the document."
  echo ""
  echo "--ignore-pandoc-crossref      Does not check if pandoc-crossref is"
  echo "                              installed. May create errors in PDF file."
}

___parse_args___ () {
  while [[ $# -gt 0 ]]
  do
    
    case "${1}" in
      --ignore-pandoc-crossref)
      _IGNORE_PANDOC_CROSSREF=${TRUE}
      ;;
      -h|--help)
      ___help___
      shift
      ;;
      *)
      ___help___
      exit
      shift
      ;;
      --)
      shift
      break
      ;;
    esac
  done
}

___test_pandoc___ () {
  which pandoc > /dev/null
  
  if [[ $? -eq 0 ]]
  then
    _FOUND_PANDOC=${TRUE}
  fi
}

___test_pandoc_crossref___ () {
  which pandoc-crossref > /dev/null
  
  if [[ $? -eq 0 ]]
  then
    _FOUND_PANDOC_CROSSREF=${TRUE}
  fi
}

___test_xdg___ () {
  which xdg-run > /dev/null
  
  if [[ $? -eq 0 ]]
  then
    _FOUND_XDG=${TRUE}
  fi
}

___main___ () {
  ___parse_args___ "${@}"
  ___test_pandoc___
  
  if [[ ${_IGNORE_PANDOC_CROSSREF} -ne ${TRUE} ]]
  then
    ___test_pandoc_crossref___
  fi
  
  if [[ ${_FOUND_PANDOC} -ne ${TRUE} ]]
  then
    echo
    echo -e "\e[31m     pandoc not found!\e[0m"
    echo ""
    echo "  Please install pandoc to build the PDF."
    echo ""
    exit 127
  fi
  
  if [[ ${_FOUND_PANDOC_CROSSREF} -ne ${TRUE} ]]
  then
    echo ""
    echo -e "\e[31m    pandoc-crossref not found!\e[0m"
    echo ""
    echo "  To build properly you will need pandoc-crossref,"
    echo "this may not not be installed by default. Please refer to"
    echo "https://github.com/lierdakil/pandoc-crossref"
    echo "for information on how to build and (add to \$PATH)."
    echo ""
    echo "  If you want to build anyway, provide the"
    echo "--ignore-pandoc-crossref flag to the script."
    echo "This will produce errors."
    exit 127
  fi
  
  pandoc -s -F pandoc-crossref\
         --from markdown --to latex\
         --reference-links\
         ${_MD_NAME}.md\
         -o ${_PDF_NAME}_pre.tex
  
  cat ${_PDF_NAME}_pre.tex | ./tex_table_verts.py > ${_PDF_NAME}_post.tex
  
  # We need to run this twice to make sure that LaTeX knows the size of things.
  xelatex ${_PDF_NAME}_post.tex
  xelatex ${_PDF_NAME}_post.tex
  mv ${_PDF_NAME}_post.pdf ${_PDF_NAME}.pdf
  rm *.tex *.toc *.aux *.log
  
  ___test_xdg___
  
  if [[ ${_FOUND_PANDOC} -eq ${TRUE} ]]
  then
    xdg-open ${_PDF_NAME}.pdf
  fi
  
}

___main___
