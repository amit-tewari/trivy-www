#!/bin/bash

## Local test paths
## used in local testing
INDEX_PATH='/var/www/html/reports'
PV_PATH='/tmp'
# GOOGLE_APPLICATION_CREDENTIALS from .envrc
#export GOOGLE_APPLICATION_CREDENTIALS=''

## K8s Deployment paths / variables
INDEX_PATH='/usr/share/nginx/html/reports'
PV_PATH='/usr/share/nginx/html/reports/tmp'
chmod a+w /usr/share/nginx/html
mkdir -p /usr/share/nginx/html/reports
chown -R nginx:nginx /usr/share/nginx/html/
echo 'Visit /reports' > /usr/share/nginx/html/index.html
cp /var/util.js //usr/share/nginx/html/reports/util.js
export GOOGLE_APPLICATION_CREDENTIALS=/sheets-service-account.json

mkdir -p ${PV_PATH}

INDEX_TXT=${INDEX_PATH}'/index.txt'
INDEX_HTML=${INDEX_PATH}'/index.html'


function fetch_reports() {
    cat $1 \
        | while  IFS=" " read -r NS report rest;
          do
              if [ "$NS" != "NAMESPACE" ];
              then
                  echo $NS $report;
                  kubectl -n ${NS} get vulnerabilityreports.aquasecurity.github.io ${report}  -o json \
                      > ${INDEX_PATH}/${report}.json;
                  echo '{}' | jq -r '(["  SEV  ","Score","  V-ID  ","Resource","Inst V", "Fix V", "CVE Link"] | (., map(length*"-")))| @csv' \
                      > ${INDEX_PATH}/${report}.txt
                  jq -r '(.report.vulnerabilities |.[]| [.severity, .score, .vulnerabilityID, .resource, .installedVersion, .fixedVersion, .primaryLink]) | @csv' ${INDEX_PATH}/${report}.json \
                      | sort -t, -k1,1 -k2,2nr  >> ${INDEX_PATH}/${report}.txt
              fi;
          done
}

function print_page_header(){
    printf "%s\n" "print header"
    echo | awk '
        BEGIN{
        printf ("<html>\n<script src=\"util.js\"></script>\n<script src=\"https://www.kryogenix.org/code/browser/sorttable/sorttable.js\"></script>\n<body>\n<div style=\"background: #ffe7e8; border: 2px solid #e66465;\">\n  <b>Clink on any table heading to sort</b>\n</div>\n<input type=\"text\" id=\"imageName\" onkeyup=\"imageFilter()\" placeholder=\"Search by Image..\" title=\"Type in a name\">\n<table border=\"1\" id=\"myTable\" class=\"sortable\">\n<thead>\n<tr>\n  <th mytable2=\"\" onclick=\"sortTable(0, \047myTable3\047)\">CRITICAL</th>\n  <th mytable2=\"\" onclick=\"sortTable(1, \047myTable3\047)\">HIGH</th>\n  <th mytable2=\"\" onclick=\"sortTable(2, \047myTable3\047)\">MEDIUM</th>\n  <th mytable2=\"\" onclick=\"sortTable(3, \047myTable3\047)\">LOW</th>\n  <th mytable2=\"\" onclick=\"sortTable(4, \047myTable3\047)\">UNKNOWN</th>\n  <th>report</th>\n  <th mytable2=\"\" onclick=\"sortTable(6, \047myTable3\047)\">Namespace </th>\n  <th mytable2=\"\" onclick=\"sortTable(7, \047myTable3\047)\">Image </th>\n  <th>TAG</th>\n  <th>Report</th>\n</tr>\n</thead>\n<tbody>\n")}
      {}
      ' > ${INDEX_HTML}
}

function print_page_footer(){
    printf "%s\n" "print footer"
    echo | awk '
        {}
        END{ printf ("</tbody></table></body><html>") }
        ' >> ${INDEX_HTML}
}

function print_page_body () {
    cat ${INDEX_TXT} \
        | awk '
            {if ($2!="NAME") printf ("<tr><td>%s</td><td> %s </td><td>%s</td><td> %s</td><td> %s</td><td> <a href=\"%s.json\">report (json)</a></td><td> %s</td><td> %s</td><td> %s</td><td> <a href=\"%s.txt\">report (txt)</a></td></tr>\n",$7,$8, $9, $10, $11, $2, $1, $3,$4,$2)}
              ' >> ${INDEX_HTML}
}

function update_gsheet(){
    # uses https://github.com/cristoper/gsheet
    # if need to push to Google Sheets
    # Needs GOOGLE_APPLICATION_CREDENTIALS env var to be set
    cat ${INDEX_TXT} | awk '{printf ("%s,%s,%s,%s,%s,%s,%s,%s,%s\n",$1,$3, $4,$6,$7,$8,$9,$10,$11)}' > /tmp/report.csv
    /usr/local/bin/gsheet newSheet --id ${GOOGLE_SHEET_ID} --name $(date +%Y%m%d)
    cat /tmp/report.csv |  /usr/local/bin/gsheet csv --id ${GOOGLE_SHEET_ID} --range "$(date +%Y%m%d)"'!A2:J290'
}

## main
kubectl get vulnerabilityreports.aquasecurity.github.io -A -o wide \
    > ${INDEX_TXT}

fetch_reports ${INDEX_TXT}

print_page_header
print_page_body
print_page_footer
# update_gsheet
