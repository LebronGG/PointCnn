#!/usr/bin/env bash


models_folder="../models/seg/"
train_files="../data/shapenet_partseg/train_val_files.txt"
val_files="../data/shapenet_partseg/test_files.txt"

python3 train_val_seg.py -t $train_files -v $val_files -s $models_folder -m pointcnn_seg -x shapenet_x8_2048_fps
