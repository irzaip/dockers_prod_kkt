import tensorflow as tf

# Test tensorflow
hello = tf.constant('Hello, TensorFlow!')
sess = tf.Session()
out = sess.run(hello)
a = tf.constant(10)
b = tf.constant(32)
sess.run(a+b)

tf.test.is_gpu_available(
    cuda_only=False,
    min_cuda_compute_capability=None
)

# Test that tensorflow supports GPUs
with tf.device('gpu:0'):
    a = tf.constant(10)
    b = tf.constant(32)
    sess = tf.Session()
    sess.run(a+b)
