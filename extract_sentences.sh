#!/bin/bash
source ./environment.sh

# ================= MKDIR =====================
mkdir -p $DOC_EMBEDDINGS
mkdir -p $MINING
mkdir -p $DICTIONARIES

# ================= AVERAGED DOCUMENT REPRESENTATION ===============
for lang in $EXTRACT_SRC_LANG $EXTRACT_TRG_LANG; do
    $PYTHON scripts/doc2vec.py --input $DATA/$EXTRACT_INPUT.$lang.tok.tc --output $DOC_EMBEDDINGS/$EXTRACT_INPUT.$lang.vec --embeddings $BWE_EMBEDDINGS/$EXTRACT_SRC_LANG-$EXTRACT_TRG_LANG/muse_unsupervised/vectors-$lang.txt --stopword_language $lang
done;

# ================= DOC_DICTIONARY_GENERATION_FOR_PREFILTERING ===============
CUDA_VISIBLE_DEVICES=$GPUS $PYTHON scripts/bilingual_nearest_neighbor.py --source_embeddings $DOC_EMBEDDINGS/$EXTRACT_INPUT.$EXTRACT_SRC_LANG.vec --target_embeddings $DOC_EMBEDDINGS/$EXTRACT_INPUT.$EXTRACT_TRG_LANG.vec --output $DICTIONARIES/DOC.$EXTRACT_INPUT.$EXTRACT_SRC_LANG-$EXTRACT_TRG_LANG.sim --knn $TOPN_DOC -m nn

# ================= DOCUMENT_SIMILARITIES ===================
$PYTHON scripts/doc_similarity.py -s $DATA/$EXTRACT_INPUT.$EXTRACT_SRC_LANG.tok.tc -t $DATA/$EXTRACT_INPUT.$EXTRACT_TRG_LANG.tok.tc -o $MINING/${EXTRACT_MINE_METHOD}_${EXTRACT_INPUT}_$EXTRACT_SRC_LANG-$EXTRACT_TRG_LANG.sim -sim $DICTIONARIES/BWE.$EXTRACT_SRC_LANG-$EXTRACT_TRG_LANG.sim -dsim $DICTIONARIES/DOC.$EXTRACT_INPUT.$EXTRACT_SRC_LANG-$EXTRACT_TRG_LANG.sim -n $THREADS -fl $EXTRACT_SRC_LANG -tl $EXTRACT_TRG_LANG -esim $DICTIONARIES/ORTH.$EXTRACT_SRC_LANG-$EXTRACT_TRG_LANG.sim -m ${EXTRACT_MINE_METHOD} ${MINE_PARAMS[${EXTRACT_INPUT}_${EXTRACT_MINE_METHOD}_${EXTRACT_SRC_LANG}_${EXTRACT_TRG_LANG}]}

# ================= MINING_&_EXTRACTING =====================
$PYTHON ./scripts/filter.py -i $MINING/${EXTRACT_MINE_METHOD}_${EXTRACT_INPUT}_$EXTRACT_SRC_LANG-$EXTRACT_TRG_LANG.sim -m $EXTRACT_FILTER_METHOD -th ${FILTER_THRESHOLDS[${EXTRACT_INPUT}_${EXTRACT_MINE_METHOD}_${EXTRACT_FILTER_METHOD}_${EXTRACT_SRC_LANG}_${EXTRACT_TRG_LANG}]} -o $MINING/${EXTRACT_MINE_METHOD}_${EXTRACT_FILTER_METHOD}_${EXTRACT_INPUT}_$EXTRACT_SRC_LANG-$EXTRACT_TRG_LANG.sim.pred

$PYTHON ./scripts/sentence_extractor.py -i $DATA/$EXTRACT_INPUT.$EXTRACT_SRC_LANG.tok.tc -ids $MINING/${EXTRACT_MINE_METHOD}_${EXTRACT_FILTER_METHOD}_${EXTRACT_INPUT}_$EXTRACT_SRC_LANG-$EXTRACT_TRG_LANG.sim.pred -c 0 -o $MINING/${EXTRACT_MINE_METHOD}_${EXTRACT_FILTER_METHOD}_${EXTRACT_INPUT}_$EXTRACT_SRC_LANG-$EXTRACT_TRG_LANG.sim.pred.$EXTRACT_SRC_LANG
$PYTHON ./scripts/sentence_extractor.py -i $DATA/$EXTRACT_INPUT.$EXTRACT_TRG_LANG.tok.tc -ids $MINING/${EXTRACT_MINE_METHOD}_${EXTRACT_FILTER_METHOD}_${EXTRACT_INPUT}_$EXTRACT_SRC_LANG-$EXTRACT_TRG_LANG.sim.pred -c 1 -o $MINING/${EXTRACT_MINE_METHOD}_${EXTRACT_FILTER_METHOD}_${EXTRACT_INPUT}_$EXTRACT_SRC_LANG-$EXTRACT_TRG_LANG.sim.pred.$EXTRACT_TRG_LANG
