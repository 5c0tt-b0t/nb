#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031

load test_helper

# `nb` (pre-init) #############################################################

@test "\`nb\` (pre-init) exits with status 0 and prints \`ls\` ouput." {
  {
    printf "\${NB_DIR}: %s\\n" "${NB_DIR}"
    printf "\${NBRC_PATH}: %s\\n" "${NBRC_PATH}"
    if [[ "${NB_DIR}" =~ /tmp/nb_test ]] &&
       [[ -e "${NB_DIR}" ]]
    then
      rm -rf "${NB_DIR}"
      [[ ! -e "${NB_DIR}" ]]
    fi
    if [[ "${NBRC_PATH}" =~ /tmp/nb_test ]] &&
       [[ -e "${NBRC_PATH}" ]]
    then
      rm -rf "${NBRC_PATH}"
      [[ ! -e "${NBRC_PATH}" ]]
    fi
  }

  run "${_NB}"

  printf "\${status}: %s\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"
  [[ "${status}" -eq 0 ]]

  [[ "${lines[8]}"  == "Initializing..."                              ]]
  [[ "${lines[9]}"  =~ Created                                        ]]
  [[ "${lines[10]}" =~ Created                                        ]]
  [[ "${lines[11]}" =~ Created                                        ]]
  [[ "${lines[14]}" == "0 notes."                                     ]]
  [[ "${lines[15]}" == "Add a note:"                                  ]]
  [[ "${lines[16]}" == "  $(_highlight 'nb add')"                     ]]
  [[ "${lines[17]}" == "Add a bookmark:"                              ]]
  [[ "${lines[18]}" == "  $(_highlight "nb <url>")"                   ]]
  [[ "${lines[19]}" == "Import a file:"                               ]]
  [[ "${lines[20]}" == "  $(_highlight "nb import (<path> | <url>)")" ]]
  [[ "${lines[21]}" == "Help information:"                            ]]
  [[ "${lines[22]}" == "  $(_highlight 'nb help')"                    ]]
}

# `nb` (empty repo) ###########################################################

@test "\`nb\` with empty repo exits with status 0 and \`ls\` output." {
  run "${_NB}" init
  run "${_NB}"

  printf "\${status}: %s\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"

  [[ "${status}" -eq 0 ]]

  [[ "${lines[1]}"  =~ ----                                           ]]
  [[ "${lines[2]}"  == "0 notes."                                     ]]
  [[ "${lines[3]}"  == "Add a note:"                                  ]]
  [[ "${lines[4]}"  == "  $(_highlight 'nb add')"                     ]]
  [[ "${lines[5]}"  == "Add a bookmark:"                              ]]
  [[ "${lines[6]}"  == "  $(_highlight "nb <url>")"                   ]]
  [[ "${lines[7]}"  == "Import a file:"                               ]]
  [[ "${lines[8]}"  == "  $(_highlight "nb import (<path> | <url>)")" ]]
  [[ "${lines[9]}"  == "Help information:"                            ]]
  [[ "${lines[10]}" == "  $(_highlight 'nb help')"                    ]]
}

# `nb` (non-empty repo) #######################################################

@test "\`nb\` with a non-empty repo exits with 0 and prints list." {
  {
    run "${_NB}" init
    "${_NB}" add "first.md" --title "one"
    "${_NB}" add "second.md" --title "two"
    "${_NB}" add "third.md" --title "three"
    _files=($(ls -t "${_NOTEBOOK_PATH}/"))
  }

  run "${_NB}"
  printf "\${status}: %s\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"
  _compare "${_files[*]}" "${lines[*]}"

  [[ "${status}" -eq 0 ]]
  [[ "${lines[2]}" =~ three ]]
  [[ "${lines[3]}" =~ two   ]]
  [[ "${lines[4]}" =~ one   ]]
}

# `nb <url>` ##################################################################

@test "\`nb\` with <url> creates bookmark." {
  {
    run "${_NB}" init
  }

  run "${_NB}" "${_BOOKMARK_URL}"
  printf "\${status}: %s\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"
  _files=($(ls "${_NOTEBOOK_PATH}/")) && _filename="${_files[0]}"

  # Returns status 0
  [[ ${status} -eq 0 ]]

  # Creates new note with bookmark filename
  [[ "${_filename}" =~ [A-Za-z0-9]+.bookmark.md ]]

  # Creates new note file with content
  [[ "${#_files[@]}" -eq 1 ]]
  _bookmark_content="\
# Example Domain

<file://${BATS_TEST_DIRNAME}/fixtures/example.com.html>

## Description

Example description.

## Content

$(cat "${BATS_TEST_DIRNAME}/fixtures/example.com.md")"
  printf "cat file: '%s'\\n" "$(cat "${_NOTEBOOK_PATH}/${_filename}")"
  printf "\${_bookmark_content}: '%s'\\n" "${_bookmark_content}"
  [[ "$(cat "${_NOTEBOOK_PATH}/${_filename}")" == "${_bookmark_content}" ]]
  grep -q '# Example Domain' "${_NOTEBOOK_PATH}"/*

  # Creates git commit
  cd "${_NOTEBOOK_PATH}" || return 1
  while [[ -n "$(git status --porcelain)" ]]
  do
    sleep 1
  done
  git log | grep -q '\[nb\] Add'

  # Adds to index
  [[ -e "${_NOTEBOOK_PATH}/.index" ]]
  [[ "$(ls "${_NOTEBOOK_PATH}")" == "$(cat "${_NOTEBOOK_PATH}/.index")" ]]

  # Prints output
  [[ "${output}" =~ Added\                    ]]
  [[ "${output}" =~ [0-9]+                    ]]
  [[ "${output}" =~ [A-Za-z0-9]+.bookmark.md  ]]
}

# `nb` NB_DIR #################################################################

@test "\`nb\` with invalid NB_DIR exits with 1." {
  {
    run "${_NB}" init
  }

  NB_DIR='/' run "${_NB}"
  printf "\${status}: %s\\n" "${status}"
  printf "\${output}: '%s'\\n" "${output}"
  _compare "${_files[*]}" "${lines[*]}"

  [[ "${status}" -eq 1 ]]
  [[ "${lines[0]}" =~ NB_DIR\ is\ not\ valid ]]
}
