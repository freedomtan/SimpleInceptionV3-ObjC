# SimpleInceptionV3-ObjC
A simple image classification test using Core ML and Inception V3 model in Objective-C

Note that the model is not included. Plese get it from [Apple](https://docs-assets.developer.apple.com/coreml/models/Inceptionv3.mlmodel) and add it to the project.

See [Apple's machine learning site](https://developer.apple.com/machine-learning/) for more information

For Swift version, see [here](https://github.com/freedomtan/SimpleInceptionV3/)

MobileNet models could be converted from Keras models using [script](https://github.com/freedomtan/coreml-mobilenet-models/). E.g., to get MobileNet 0.5/160,
```
  python mobilenets.py --alpha 0.50 --image_size 160
```
