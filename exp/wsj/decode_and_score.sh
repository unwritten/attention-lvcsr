#!/bin/bash

set -e

KU=$KALDI_ROOT/egs/wsj/s5/utils
KL=$KALDI_ROOT/egs/wsj/s5/local

beam_search_opts=""
lm_opts=""
part=test_dev92
DATASET=$FUEL_DATA_PATH/wsj.h5
lexicon=$FUEL_DATA_PATH/WSJ/lexicon.txt


. $KU/parse_options.sh

if [ $# -ne 2 ]; then
	echo "usage: `basename $0` <net> <dir>"
	echo "options:"
	echo "		--part name					#partition to score"
	echo "		--beam_serch_opts 'opts'	#opts passed to beam search"
	echo "		--lm_opts 'opts'			#opts about the LM"
	echo "Example:"
	cat << EOF
BLOCKS_CONFIG=`pwd`/blocks_conf.yaml THEANO_FLAGS=device=gpu exp/wsj/decode_and_score.sh --beam-search-opts "--beam-search-normalize" --lm-opts "net.lm.path './wsj_unigram_no_bos/LG_pushed_withsyms.fst' net.lm.weight 0.0" wsj_models/wsj11/wsj_jan_best.zip jch11-vanilla "
EOF
	exit 1
fi

model=$1
dir=$2

mkdir -p $dir

set -x
$LVSR/lvsr/run.py --params=true \
	$beam_search_opts \
	--part $part \
	--decoded-save=$dir/$part-decoded.out search $model `dirname $model`/*.yaml \
	net.lm.type_ "'fst'" $lm_opts > $dir/beam_search.log 2>&1

#we cannot use stdout pipe, because of some pydot parser error getting printed to the stdout :(
$LVSR/bin/kaldi2fuel.py $DATASET read_text --subset $part characters $dir/tmp
cat $dir/tmp | sort > $dir/$part-groundtruth-characters.txt

$LVSR/bin/kaldi2fuel.py $DATASET read_raw_text --subset $part kaldi_text $dir/tmp
cat $dir/tmp | sort | $KL/wer_ref_filter > $dir/$part-groundtruth-text.txt

rm $dir/tmp

$LVSR/exp/wsj/score.sh $dir $part
