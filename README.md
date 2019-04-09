# PointCNN: Convolution On X-Transformed Points

Created by <a href="http://yangyan.li" target="_blank">Yangyan Li</a>, Rui Bu, Mingchao Sun, Wei Wu, Xinhan Di, and Baoquan Chen.

## Introduction

PointCNN is a simple and general framework for feature learning from point cloud, which refreshed five benchmark records in point cloud processing (as of Jan. 23, 2018), including:

* classification accuracy on ModelNet40 (**91.7%**, with 1024 input points only)
* segmentation part averaged IoU on ShapeNet Parts (**82%**)
* segmentation mean IoU on S3DIS (**66.2%**,test on Area1)


See our <a href="http://arxiv.org/abs/1801.07791" target="_blank">preprint on arXiv</a> (accepted to NeurIPS 2018) for more details.

Pretrained models can be downloaded from <a href="https://1drv.ms/f/s!AiHh4BK32df6gYFCzzpRz0nsJmQxSg" target="_blank">here</a>.

### Performance on Recent Benchmarks
<a href="https://arxiv.org/abs/1812.02713" target="_blank">PartNet: A Large-scale Benchmark for Fine-grained and Hierarchical Part-level 3D Object Understanding</a>

<a href="https://arxiv.org/abs/1812.06216" target="_blank">ABC: A Big CAD Model Dataset For Geometric Deep Learning</a>

### Practical Applications
<a href="https://medium.com/geoai/3d-cities-deep-learning-in-three-dimensional-space-29f9dafdfd73" target="_blank">3D cities: Deep Learning in three-dimensional space</a> (from <a href="https://www.esri.com/en-us/home" target="_blank">Esri</a>)

### More Implementations
* <a href="https://github.com/rusty1s/pytorch_geometric" target="_blank">Pytorch implementation from PyTorch Geometric</a>
* <a href="https://github.com/hxdengBerkeley/PointCNN.Pytorch" target="_blank">Pytorch implementation from Berkeley CS294-131 Course Proj</a>
* <a href="https://github.com/chinakook/PointCNN.MX" target="_blank">MXNet implementation</a>

**We highly welcome issues, rather than emails, for PointCNN related questions.**

## License
Our code is released under MIT License (see LICENSE file for details).

## Code Organization
The core X-Conv and PointCNN architecture are defined in [pointcnn.py](pointcnn.py).

The network/training/data augmentation hyper parameters for classification tasks are defined in [pointcnn_cls](pointcnn_cls), for segmentation tasks are defined in [pointcnn_seg](pointcnn_seg).

### Explanation of X-Conv and X-DeConv Parameters
Take the xconv_params and xdconv_params from [shapenet_x8_2048_fps.py](pointcnn_seg/shapenet_x8_2048_fps.py) for example:
```
xconv_param_name = ('K', 'D', 'P', 'C', 'links')
xconv_params = [dict(zip(xconv_param_name, xconv_param)) for xconv_param in
                [(8, 1, -1, 32 * x, []),
                 (12, 2, 768, 32 * x, []),
                 (16, 2, 384, 64 * x, []),
                 (16, 6, 128, 128 * x, [])]]

xdconv_param_name = ('K', 'D', 'pts_layer_idx', 'qrs_layer_idx')
xdconv_params = [dict(zip(xdconv_param_name, xdconv_param)) for xdconv_param in
                 [(16, 6, 3, 2),
                  (12, 6, 2, 1),
                  (8, 6, 1, 0),
                  (8, 4, 0, 0)]]
```
Each element in xconv_params is a tuple of (K, D, P, C, links), where K is the neighborhood size, D is the dilation rate, P is the representative point number in the output (-1 means all input points are output representative points), and C is the output channel number. The links are used for adding DenseNet style links, e.g., [-1, -2] will tell the current layer to receive inputs from the previous two layers. from Each element specifies the parameters of one X-Conv layer, and they are stacked to create a deep network.

Each element in xdconv_params is a tuple of (K, D, pts_layer_idx, qrs_layer_idx), where K and D have the same meaning as that in xconv_params, pts_layer_idx specifies the output of which X-Conv layer (from the xconv_params) will be the input of this X-DeConv layer, and qrs_layer_idx specifies the output of which X-Conv layer (from the xconv_params) will be forwarded and fused with the output of this X-DeConv layer. The P and C parameters of this X-DeConv layer is also determined by qrs_layer_idx. Similarly, each element specifies the parameters of one X-DeConv layer, and they are stacked to create a deep network.


## PointCNN Usage

PointCNN is implemented and tested with Tensorflow 1.6 in python3 scripts. **Tensorflow before 1.5 version is not recommended, because of API.** It has dependencies on some python packages such as transforms3d, h5py, plyfile, and maybe more if it complains. Install these packages before the use of PointCNN.

If you can only use Tensorflow 1.5 because of OS factor(UBUNTU 14.04),please modify "isnan()" to "std::nan()" in "/usr/local/lib/python3.5/dist-packages/tensorflow/include/tensorflow/core/framework/numeric_types.h" line 49

Here we list the commands for training/evaluating PointCNN on classification and segmentation tasks on multiple datasets.

* ### Classification

  * #### ModelNet40
  ```
  cd data_conversions
  python3 ./download_datasets.py -d modelnet
  cd ../pointcnn_cls
  ./train_val_modelnet.sh -g 0 -x modelnet_x3_l4
  ```

* ### Segmentation

  We use farthest point sampling (the implementation from <a href="https://github.com/charlesq34/pointnet2" target="_blank">PointNet++</a>) in segmentation tasks. Compile FPS before the training/evaluation:
  ```
  cd sampling
  bash tf_sampling_compile.sh
  ```

  * #### ShapeNet
  ```
  cd data_conversions
  python3 ./download_datasets.py -d shapenet_partseg
  python3 ./prepare_partseg_data.py -f ../../data/shapenet_partseg
  cd ../pointcnn_seg
  ./train_val_shapenet.sh -g 0 -x shapenet_x8_2048_fps
  ./test_shapenet.sh -g 0 -x shapenet_x8_2048_fps -l ../../models/seg/pointcnn_seg_shapenet_x8_2048_fps_xxxx/ckpts/iter-xxxxx -r 10
  cd ../evaluation
  python3 eval_shapenet_seg.py -g ../../data/shapenet_partseg/test_label -p ../../data/shapenet_partseg/test_data_pred_10 -a
  ```

  * #### S3DIS
  Please refer to [data_conversions](data_conversions/README.md) for downloading S3DIS, then:
  ```
  cd data_conversions
  python3 prepare_s3dis_label.py
  python3 prepare_s3dis_data.py
  python3 prepare_s3dis_filelists.py
  cd ../pointcnn_seg
  ./train_val_s3dis.sh -g 0 -x s3dis_x8_2048_fps -a 1
  ./test_s3dis.sh -g 0 -x s3dis_x8_2048_fps -a 1 -l ../../models/seg/pointcnn_seg_s3dis_x8_2048_fps_xxxx/ckpts/iter-xxxxx -r 4
  cd ../evaluation
  此处已经改写为可直接运行
  python3 s3dis_merge.py -d <path to *_pred.h5>
  python3 s3dis_merge.py
  python3 eval_s3dis.py
  ```
I use a hidden marker file to note when prepare is finished to avoid re-processing. This cache can be invalidated by deleting the markers. 
 
 Please notice that these command just for Area 1 (specified by -a 1 option) validation. Results on other Areas can be computed by iterating -a option.


* ### Tensorboard
  If you want to moniter your train step, we recommand you use following command
  ```
  cd <your path>/PointCNN
  tensorboard --logdir=../models/<seg/cls> <--port=6006>
  ```