# convert file to clean TSV

import sys

infile = sys.argv[1]
outfile = sys.argv[2]

main_header='SECTION'
with open(infile, 'rb') as infile, open(outfile, 'wb') as out:
	for line in infile:
		
		if '----' in line:
			main_header = line.strip().split(' ')[0]
			continue
		
		l = line.strip().split('\t')
		
		if line.startswith('\t'):
			out.write(main_header+'\t'+subhead+'\t'+'\t'.join(l[1:len(l)])+'\n')
			continue

		if l[0] == 'FRiP':
			subhead = 'FRiP_'+subhead
		elif l[0] != '':
			subhead = l[0]		
		if len(l) > 1:
			out.write(main_header+'\t'+subhead+'\t'+'\t'.join(l[1:len(l)])+'\n')
