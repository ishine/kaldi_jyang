#!/bin/bash

. path.sh
. cmd.sh


## Need improvement: assume kl/wer/per results file listed in the same order (name of subset)


cmd=run.pl
threshold=0.3 ## KL_compute skip frames with phones "SIL" "SPN" "NSN" post sum larger than threshold
postdir_word=post/nnet5c/word_tgpr_5k_subset
postdir_phone=post/nnet5c/phone_graph_3gram_subset
werfile=eval92_results/eval92_wer.txt
perfile=eval92_results/eval92_per.txt
#kl_dir=KL_div/eval92_word_tgpr_5k_vs_phone_3gram
kl_dir=KL_div/eval92_word_tgpr_5k_vs_phone_3gram_skip_frame_th_${threshold}
suffix=("0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "a" "b" "c" "d");
#suffix=("1");
#performance_dir=performance/eval92_word_tgpr_5k_vs_phone_3gram
performance_dir=performance/eval92_word_tgpr_5k_vs_phone_3gram_skip_frame_th_${threshold}
nj=8
stage=2
################## KL setting ###################
kernel_size=11
num_of_classes=42
medfilt_flag=yes
window=0
#################################################

if [ ! -d $performance_dir ]; then
	mkdir -p $performance_dir
fi


for s in "${suffix[@]}"
do
 (
  postdir_word=${postdir_word}_${s}
  postdir_phone=${postdir_phone}_${s}
  kl_dir=${kl_dir}/subset_${s}

  if [ ! -d $kl_dir ]; then
	mkdir -p $kl_dir
  fi

  if [ ! -d $postdir_word ] || [ ! -d $postdir_phone ]; then
	 echo "Post word/phone directory does not exist !"
	 exit 1;
  fi

  if [ $stage -le 0 ]; then
  for n in $(seq $nj) 
  do
	  (
   if [ -f $postdir_word/lat.$n.phone.post.matrix ] && [ -f $postdir_phone/lat.$n.phone.post.matrix ]; then
   tools/KL_div_enhance.py $postdir_word/lat.$n.phone.post.matrix $postdir_phone/lat.$n.phone.post.matrix $kl_dir/KL_sys_medfilt_${kernel_size}_phone_window_${window}.$n.txt $num_of_classes $medfilt_flag $kernel_size $window $threshold
   else
	   echo "Missing the other  post matrix: lat.$n.phone.post.matrix "
           echo "Check the $postdir_word and $postdir_phone "
           exit 1	   
   fi
   ) &
   done
   wait
  fi

  if [ -f $kl_dir/KL_sys_medfilt_${kernel_size}_phone_window_${window}.1.txt ]; then 
   cat $kl_dir/KL_sys_medfilt_${kernel_size}_phone_window_${window}.*.txt > $kl_dir/KL_sys_medfilt_${kernel_size}_phone_window_${window}.txt
   awk 'NF!=1{sum=0;for (n=1;n<=NF;++n) sum+=$n; print $1" "sum" "(NF-1)" "sum/(NF-1)}' $kl_dir/KL_sys_medfilt_${kernel_size}_phone_window_${window}.txt | sort > $kl_dir/KL_sum_per_utt_sys_medfilt_${kernel_size}_phone_window_${window}.txt
   awk '{sum+=$2;frame+=$3}END{print "subset "name" sum:"sum",frames:"frame",avrg: "sum/frame;}' name=$s $kl_dir/KL_sum_per_utt_sys_medfilt_${kernel_size}_phone_window_${window}.txt > $kl_dir/KL_avrg.txt
   cp $kl_dir/KL_avrg.txt $performance_dir/KL_avrg_win_${window}_sys_medfilt_${kernel_size}_phone_subset_${s}.txt
   else
	   echo "Didn't compute average kl"
   fi
   ) &
done
wait

cat $performance_dir/KL_avrg_win_${window}_sys_medfilt_${kernel_size}_phone_subset_*.txt | \
	cut -d " " -f2-2,4-4 - > $performance_dir/eval92_kl_avrg.txt
paste -d " " <(cat $performance_dir/eval92_kl_avrg.txt) <(cut -d " " -f2 $werfile) | sort -k3 -n > $performance_dir/eval92_kl_avrg_vs_wer.txt
paste -d " " <(cat $performance_dir/eval92_kl_avrg.txt) <(cut -d " " -f2 $perfile) | sort -k3 -n > $performance_dir/eval92_kl_avrg_vs_per.txt
