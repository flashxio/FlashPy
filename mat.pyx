import numpy as np
import ctypes
# "cimport" is used to import special compile-time information
# about the numpy module (this is stored in a file numpy.pxd which is
# currently part of the Cython distribution).
cimport numpy as np
from libc.stdlib cimport free, malloc
from libc.stdint cimport intptr_t
from libcpp.vector cimport vector
from libcpp.string cimport string
from libcpp.utility cimport pair
from libcpp cimport bool as cbool
from libc.string cimport memcpy

from cpython cimport array
import array
import traceback

np.import_array()

cdef enum bulk_op_idx_t:
    OP_ADD, OP_SUB, OP_MUL, OP_DIV
    OP_MIN, OP_MAX,
    OP_POW,
    OP_EQ, OP_NEQ, OP_GT, OP_GE, OP_LT, OP_LE,
    OP_OR, OP_AND,
    OP_MOD, OP_IDIV

bop_add = OP_ADD
bop_sub = OP_SUB
bop_mul = OP_MUL
bop_div = OP_DIV
bop_min = OP_MIN
bop_max = OP_MAX
bop_pow = OP_POW
bop_eq = OP_EQ
bop_neq = OP_NEQ
bop_gt = OP_GT
bop_ge = OP_GE
bop_lt = OP_LT
bop_le = OP_LE
bop_or = OP_OR
bop_and = OP_AND
bop_mod = OP_MOD
bop_idiv = OP_IDIV

cdef enum bulk_uop_idx_t:
    UOP_NEG, UOP_SQRT, UOP_ABS, UOP_NOT, UOP_SQ,
    UOP_CEIL, UOP_FLOOR, UOP_ROUND,
    UOP_LOG, UOP_LOG2, UOP_LOG10,
    UOP_SIGN

uop_neg = UOP_NEG
uop_sqrt = UOP_SQRT
uop_abs = UOP_ABS
uop_not = UOP_NOT
uop_sq = UOP_SQ
uop_ceil = UOP_CEIL
uop_floor = UOP_FLOOR
uop_round = UOP_ROUND
uop_log = UOP_LOG
uop_log2 = UOP_LOG2
uop_log10 = UOP_LOG10
uop_sign = UOP_SIGN

cdef enum agg_op_idx_t:
    AGG_COUNT, AGG_FIND_NEXT, AGG_FIND_PREV, AGG_ARGMIN, AGG_ARGMAX,
    AGG_MIN, AGG_MAX, AGG_SUM, AGG_PROD, AGG_AND, AGG_OR

agg_count = AGG_COUNT
agg_find_next = AGG_FIND_NEXT
agg_find_prev = AGG_FIND_PREV
agg_argmin = AGG_ARGMIN
agg_argmax = AGG_ARGMAX
agg_min = AGG_MIN
agg_max = AGG_MAX
agg_sum = AGG_SUM
agg_prod = AGG_PROD
agg_and = AGG_AND
agg_or = AGG_OR

cdef extern from "MatrixWrapper.h" namespace "flashpy":
    cdef cbool init_flashpy_c(const string file)

cdef extern from "MatrixWrapper.h" namespace "flashpy":
    cdef cppclass scalar_wrapper:
        scalar_wrapper()
        const char *get_raw() const;

cdef extern from "MatrixWrapper.h" namespace "flashpy":
    cdef scalar_wrapper create_scalar_wrapper[T](T x)

cdef extern from "MatrixWrapper.h" namespace "flashpy":
    cdef cppclass matrix_wrapper:
        matrix_wrapper()
        # create a vector with data from "data_addr".
        matrix_wrapper(intptr_t data_addr, size_t length,
                const string &t) except+
        # create a matrix with data from "data_addr".
        matrix_wrapper(intptr_t data_addr, size_t nrow, size_t ncol,
                const string &t, const string layout) except+
        # create an empty vector with the specified size
        matrix_wrapper(size_t length, string t) except+
        # create an empty matrix with the specified size
        matrix_wrapper(size_t nrow, size_t ncol, string t, string layout) except+

        void init_seq[T](T start, T stride, cbool byrow)
        void init_const_float(double val) except+
        void init_const_int(long val) except+

        @staticmethod
        matrix_wrapper cbind(vector[matrix_wrapper] &mats) except+
        @staticmethod
        matrix_wrapper rbind(vector[matrix_wrapper] &mats) except+

        void set_cached(cbool)

        matrix_wrapper as_factor(int num_levels) except+
        matrix_wrapper as_vector() except+
        matrix_wrapper as_matrix() const

        size_t get_num_rows() const
        size_t get_num_cols() const
        size_t get_entry_size() const
        string get_type_str() const
        np.NPY_TYPES get_type_py() const
        string get_layout() const

        cbool is_floating_point() const
        cbool is_in_mem() const
        cbool is_virtual() const
        cbool is_vector() const
        cbool is_valid() const

        cbool materialize_self() const
        matrix_wrapper cast_ele_type(string dtyp) except+

        matrix_wrapper get_col(long idx) except+
        matrix_wrapper get_row(long idx) except+
        matrix_wrapper get_cols(const vector[long] &idxs) except+
        matrix_wrapper get_rows(const vector[long] &idxs) except+
        matrix_wrapper get_cols(long start, long stop, long step) except+
        matrix_wrapper get_rows(long start, long stop, long step) except+
        matrix_wrapper get_cols(matrix_wrapper idxs) except+
        matrix_wrapper get_rows(matrix_wrapper idxs) except+
        matrix_wrapper get_eles(matrix_wrapper idxs) except+

        matrix_wrapper set_cols(const vector[long] &idxs, matrix_wrapper cols) except+
        matrix_wrapper set_rows(const vector[long] &idxs, matrix_wrapper rows) except+
        matrix_wrapper set_cols(long start, long stop, long step, matrix_wrapper cols) except+
        matrix_wrapper set_rows(long start, long stop, long step, matrix_wrapper rows) except+
        cbool copy_rows_to(char *arr, size_t len) const
        matrix_wrapper transpose() const
        matrix_wrapper conv_store(cbool in_mem, int num_nodes) const
        matrix_wrapper conv_layout(const string layout) const
        matrix_wrapper inner_prod(matrix_wrapper m, bulk_op_idx_t left_op,
                bulk_op_idx_t right_op) except+
        matrix_wrapper multiply(matrix_wrapper m) except+
        matrix_wrapper aggregate(agg_op_idx_t op)
        matrix_wrapper agg_row(agg_op_idx_t op) const
        matrix_wrapper agg_col(agg_op_idx_t op) const
        matrix_wrapper cum_row(agg_op_idx_t op) const
        matrix_wrapper cum_col(agg_op_idx_t op) const
        matrix_wrapper groupby_row(matrix_wrapper labels, agg_op_idx_t op) except+
        pair[matrix_wrapper, matrix_wrapper] groupby(agg_op_idx_t op, cbool with_val) const
        matrix_wrapper mapply_cols(matrix_wrapper vals, bulk_op_idx_t op) except+
        matrix_wrapper mapply_rows(matrix_wrapper vals, bulk_op_idx_t op) except+
        matrix_wrapper mapply2(matrix_wrapper m, bulk_op_idx_t op) except+
        matrix_wrapper sapply(bulk_uop_idx_t op) const
        matrix_wrapper apply_scalar(scalar_wrapper var, bulk_op_idx_t op) except+
        matrix_wrapper ifelse(matrix_wrapper x, matrix_wrapper y) const

def is_idx_range_all(idxs):
    if (isinstance(idxs, slice)):
        if (idxs.start is None and idxs.stop is None and idxs.step is None):
            return True
    return False

def normalize_idxs(slice idxs, max_len):
    if (idxs.start is None):
        start = 0
    else:
        start = idxs.start
    if (idxs.stop is None):
        stop = max_len
    else:
        stop = idxs.stop
    if (idxs.step is None):
        step = 1
    else:
        step = idxs.step
    return slice(start, stop, step)

class flagsobj:
    def __init__(self):
        self.c_contiguous = False
        self.f_contiguous = False
        self.owndata = True
        self.writable = False
        self.aligned = True
        self.updateifcopy = False

    def set_layout(self, layout):
        if (layout == "C"):
            self.c_contiguous = True
            self.f_contiguous = False
        elif (layout == "F"):
            self.c_contiguous = False
            self.f_contiguous = True
        else:
            raise ValueError("Invalid layout")

cdef class PyMatrix:
    cdef matrix_wrapper mat      # hold a C++ instance which we're wrapping
    cdef readonly int ndim
    cdef readonly object shape
    cdef readonly object dtype
    cdef readonly object flags
    cdef readonly long size
    cdef readonly long itemsize
    cdef readonly long nbytes
    cdef readonly PyMatrix T

    def __cinit__(self):
        self.mat = matrix_wrapper()

    def __init__(self):
        self.ndim = 0
        self.shape = (0, 0)
        self.flags = flagsobj()

    def __array__(self, dtype = None):
        #if (np.prod(self.shape) > 20):
        #    traceback.print_stack()
        #    print("\n")
        cdef PyMatrix arr
        if (dtype is None):
            arr = self
        else:
            arr = self.cast_ele_type(dtype)
        cdef np.npy_intp shape[2]
        shape[0] = arr.shape[0]
        if (arr.ndim >= 2):
            shape[1] = arr.shape[1]
        tmp = np.PyArray_SimpleNew(arr.ndim, shape, arr.mat.get_type_py())
        arr.mat.copy_rows_to(np.PyArray_BYTES(tmp),
                arr.mat.get_num_rows() * arr.mat.get_num_cols() * arr.mat.get_entry_size())
        return tmp

    # Special Methods Table
    # http://cython.readthedocs.io/en/latest/src/reference/special_methods_table.html

    def __richcmp__(x, y, int op):
        cdef PyMatrix ret = PyMatrix()
        # Rich comparisons:
        # http://cython.readthedocs.io/en/latest/src/userguide/special_methods.html#rich-comparisons
        # <   0
        # ==  2
        # >   4
        # <=  1
        # !=  3
        # >=  5
        if (isinstance(x, PyMatrix)):
            if (op == 0):
                ret = x.mapply2(y, OP_LT)
            elif (op == 2):
                ret = x.mapply2(y, OP_EQ)
            elif (op == 4):
                ret = x.mapply2(y, OP_GT)
            elif (op == 1):
                ret = x.mapply2(y, OP_LE)
            elif (op == 3):
                ret = x.mapply2(y, OP_NEQ)
            elif (op == 5):
                ret = x.mapply2(y, OP_GE)
            else:
                raise ValueError("invalid argument")
        else:
            if (op == 0):
                ret = y.mapply2(x, OP_GE)
            elif (op == 2):
                ret = y.mapply2(x, OP_EQ)
            elif (op == 4):
                ret = y.mapply2(x, OP_LE)
            elif (op == 1):
                ret = y.mapply2(x, OP_GT)
            elif (op == 3):
                ret = y.mapply2(x, OP_NEQ)
            elif (op == 5):
                ret = y.mapply2(x, OP_LT)
            else:
                raise ValueError("invalid argument")
        return ret

    def __add__(x, y):
        if (isinstance(x, PyMatrix)):
            return x.mapply2(y, OP_ADD)
        else:
            return y.mapply2(x, OP_ADD)

    def __sub__(x, y):
        if (np.isscalar(x)):
            x = create_const(x, y.shape)
        elif (isinstance(x, np.ndarray)):
            x = array(x)
        return x.mapply2(y, OP_SUB)

    def __mul__(x, y):
        if (isinstance(x, PyMatrix)):
            return x.mapply2(y, OP_MUL)
        else:
            return y.mapply2(x, OP_MUL)

    def __div__(x, y):
        if (np.isscalar(x)):
            x = create_const(x, y.shape)
        elif (isinstance(x, np.ndarray)):
            x = array(x)
        return x.mapply2(y, OP_DIV)

    def __truediv__(x, y):
        if (np.isscalar(x)):
            x = create_const(x, y.shape)
        elif (isinstance(x, np.ndarray)):
            x = array(x)
        return x.mapply2(y, OP_DIV)

    def __floordiv__(x, y):
        if (np.isscalar(x)):
            x = create_const(x, y.shape)
        elif (isinstance(x, np.ndarray)):
            x = array(x)
        return x.mapply2(y, OP_IDIV)

    def __mod__(x, y):
        if (np.isscalar(x)):
            x = create_const(x, y.shape)
        elif (isinstance(x, np.ndarray)):
            x = array(x)
        return x.mapply2(y, OP_MOD)

    def __and__(x, y):
        if (isinstance(x, PyMatrix)):
            return x.mapply2(y, OP_AND)
        else:
            return y.mapply2(x, OP_AND)

    def __or__(x, y):
        if (isinstance(x, PyMatrix)):
            return x.mapply2(y, OP_OR)
        else:
            return y.mapply2(x, OP_OR)

    def __pow__(x, y, z):
        if (np.isscalar(x)):
            x = create_const(x, y.shape)
        elif (isinstance(x, np.ndarray)):
            x = array(x)
        return x.mapply2(y, OP_POW)

    def __neg__(self):
        return self.sapply(UOP_NEG)

    def __abs__(self):
        return self.sapply(UOP_ABS)

    def __invert__(self):
        if (self.dtype == np.dtype(np.bool)):
            return self.sapply(UOP_NOT)
        # TODO I need to a specialized operator for this.
        elif (self.mat.is_floating_point()):
            raise TypeError("invert not supprted for floating points.")
        else:
            return -self-1

    def __len__(self):
        return self.mat.get_num_rows()

    def __getitem__(self, key):
        cdef PyMatrix ret = PyMatrix()
        if (isinstance(key, tuple) and len(key) >= 2):
            if (len(key) > 2):
                raise IndexError("too many indices for array")
            if (isinstance(key[0], slice) or isinstance(key[1], slice)):
                if (self.ndim == 1 or self.shape[0] > self.shape[1]):
                    ret = self.get_cols(key[1])
                    ret = ret.get_rows(key[0])
                else:
                    ret = self.get_rows(key[0])
                    ret = self.get_cols(key[1])
            else:
                ret = self.get_eles(key[0], key[1])
        else:
            ret = self.get_rows(key)
        return ret

    def __setitem__(self, key, val):
        if (isinstance(key, tuple) and len(key) >= 2):
            if (len(key) > 2):
                raise IndexError("too many indices for array")
            elif (is_idx_range_all(key[0])):
                self.set_cols(key[1], val)
            elif (is_idx_range_all(key[1])):
                self.set_rows(key[0], val)
            else:
                raise IndexError("can't set individual elements")
        elif ((isinstance(key, np.ndarray) or isinstance(key, PyMatrix))
                and key.dtype == np.bool):
            key = asarray(key)
            # TODO what if val isn't a scalar.
            self.assign(where(key, self, val))
        else:
            self.set_rows(key, val)

    def __str__(self):
        return str(np.array(self))

    def init_attr(self, T=None):
        if (not self.mat.is_valid()):
            raise ValueError("invalid matrix")
        if (self.mat.is_vector()):
            self.shape = (self.mat.get_num_rows(),)
            self.ndim = 1
        else:
            self.shape = (self.mat.get_num_rows(), self.mat.get_num_cols())
            self.ndim = 2
        self.dtype = np.dtype(self.mat.get_type_str())
        self.flags.set_layout(self.mat.get_layout())
        self.size = self.mat.get_num_rows() * self.mat.get_num_cols()
        self.itemsize = self.mat.get_entry_size()
        self.nbytes = self.size * self.itemsize
        if (self.ndim < 2):
            self.T = self
        elif (T is None):
            self.T = self.transpose()
        else:
            self.T = T

    # These are functions in numpy

    def reshape(self, shape, order='C'):
        shape = np.array(shape)
        if (shape[0] == -1):
            shape[0] = self.shape[0]
        if (len(shape) >= 2 and shape[1] == -1 and len(self.shape) >= 2):
            shape[1] = self.shape[1]

        if (len(self) != np.prod(shape)):
            raise ValueError("incompatible shape")
        if (len(shape) == 1):
            return self.as_vector()
        elif (len(shape) == 2 and self.ndim == 1):
            if (shape[1] == 1):
                return self.as_matrix()
            elif (shape[2] == 1):
                return self.as_matrix().T
            else:
                raise NotImplementedError("Can't convert a vector to a matrix")
        else:
            raise NotImplementedError("Can't conversion on multi-dimensional")

    def ravel(self, order='C'):
        if (self.ndim == 1):
            return self
        elif (self.shape[0] == 1 or self.shape[1] == 1):
            return self.as_vector()
        else:
            return None

    def copy(self, order='K'):
        if (order == 'K'):
            return self
        else:
            return self.conv_layout(order)

    def astype(self, dtype, order='K', casting='unsafe', subok=True, copy=True):
        # TODO I need to check casting
        arr = self.cast_ele_type(dtype)
        if (order == 'C' or order == 'F'):
            arr = arr.conv_layout(order)
        return arr

    def dot(self, b, out=None):
        cdef PyMatrix res = PyMatrix()
        if (self.ndim == 1 and b.ndim == 1):
            res = self.as_matrix().transpose().multiply(b)
        else:
            res = self.multiply(b)
        if (out is not None):
            out.assign(res)
        return res

    def sum(self, axis=None, dtype=None, out=None, keepdims=False):
        arr = self
        if (arr.dtype == np.bool):
            arr = arr.cast_ele_type(np.int)
        return arr.aggregate_(AGG_SUM, axis, dtype, out, keepdims)

    def prod(self, axis=None, dtype=None, out=None, keepdims=False):
        arr = self
        if (arr.dtype == np.bool):
            arr = arr.cast_ele_type(np.int)
        return arr.aggregate_(AGG_PROD, axis, dtype, out, keepdims)

    def mean(self, axis=None, dtype=None, out=None, keepdims=False):
        cdef PyMatrix a = self
        if (a.dtype == np.bool):
            a = a.cast_ele_type(np.int)
        if (not a.mat.is_floating_point()):
            a = a.cast_ele_type("d")
        s = a.sum(axis, dtype, out, keepdims)
        if axis is None:
            return s/a.mat.get_num_rows()/a.mat.get_num_cols()
        else:
            return s/a.shape[axis]

    def var(self, axis=None, dtype=None, out=None, ddof=0, keepdims=False):
        cdef PyMatrix a = self
        if (a.dtype == np.bool):
            a = a.cast_ele_type(np.int)
        if (not a.mat.is_floating_point()):
            a = a.cast_ele_type("d")
        e1 = (a * a).mean(axis, dtype, out, keepdims)
        e2 = a.mean(axis, dtype, out, keepdims)
        return e1 - e2 * e2

    def min(self, axis=None, out=None, keepdims=False):
        return self.aggregate_(AGG_MIN, axis, None, out, keepdims)

    def max(self, axis=None, out=None, keepdims=False):
        return self.aggregate_(AGG_MAX, axis, None, out, keepdims)

    def argmin(self, axis=None, out=None):
        # TODO this is a bad way of implementing this.
        if ((self.shape[0] > self.shape[1] and axis == 0)
                or (self.shape[0] < self.shape[1] and axis == 1)):
            return np.argmin(np.array(self), axis, out)
        cdef PyMatrix ret = self.aggregate_(AGG_ARGMIN, axis, None, out, False)
        # ARGMIN return int32, but we want int64 to match NumPy
        return ret.cast_ele_type("l")

    def argmax(self, axis=None, out=None):
        # TODO this is a bad way of implementing this.
        if ((self.shape[0] > self.shape[1] and axis == 0)
                or (self.shape[0] < self.shape[1] and axis == 1)):
            return np.argmax(np.array(self), axis, out)
        cdef PyMatrix ret = self.aggregate_(AGG_ARGMAX, axis, None, out, False)
        # ARGMIN return int32, but we want int64 to match NumPy
        return ret.cast_ele_type("l")

    def all(self, axis=None, out=None, keepdims=False):
        new_arr = self.cast_ele_type(np.bool)
        return new_arr.aggregate_(AGG_AND, axis, None, out, keepdims)

    def any(self, axis=None, out=None, keepdims=False):
        new_arr = self.cast_ele_type(np.bool)
        return new_arr.aggregate_(AGG_OR, axis, None, out, keepdims)

    def cumprod(self, axis=None, dtype=None, out=None):
        return self.cum_(AGG_PROD, axis, dtype, out)

    def cumsum(self, axis=None, dtype=None, out=None):
        return self.cum_(AGG_SUM, axis, dtype, out)

    # These are specific for FlashMatrix.

    def set_cached(self, cached):
        self.mat.set_cached(cached)

    def is_in_mem(self):
        return self.mat.is_in_mem()

    def is_virtual(self):
        return self.mat.is_virtual()

    def materialize_self(self):
        return self.mat.materialize_self()

    def get_rows(self, idxs):
        cdef PyMatrix idx_mat
        cdef PyMatrix ret = PyMatrix()
        cdef long *addr
        cdef vector[long] cidxs
        if (isinstance(idxs, xrange)):
            # TODO This isn't a good way of handling xrange.
            idxs = np.array(idxs)
        if (np.isscalar(idxs)):
            ret.mat = self.mat.get_row(idxs)
        elif (isinstance(idxs, list)):
            cidxs = idxs
            ret.mat = self.mat.get_rows(cidxs)
        elif (isinstance(idxs, slice)):
            if (is_idx_range_all(idxs)):
                ret.mat = self.mat
            else:
                idxs = normalize_idxs(idxs, self.shape[0])
                ret.mat = self.mat.get_rows(idxs.start, idxs.stop, idxs.step)
        elif (isinstance(idxs, np.ndarray)):
            idxs = np.array(idxs, dtype='l')
            addr = <long *>np.PyArray_DATA(idxs)
            cidxs.assign(addr, addr + len(idxs))
            ret.mat = self.mat.get_rows(cidxs)
        elif (isinstance(idxs, PyMatrix)):
            idx_mat = idxs
            ret.mat = self.mat.get_rows(idx_mat.mat)
        elif (idxs is None):
            if (self.ndim >= 2):
                raise IndexError("doesn't support high dimensional array")
            # If this is a vector, we return a one-row matrix.
            return self.as_matrix().transpose()
        else:
            raise ValueError("invalid index")
        ret.init_attr()
        return ret

    def get_cols(self, idxs):
        cdef PyMatrix idx_mat
        cdef PyMatrix ret = PyMatrix()
        cdef long *addr
        cdef vector[long] cidxs
        if (isinstance(idxs, xrange)):
            # TODO This isn't a good way of handling xrange.
            idxs = np.array(idxs)
        if (np.isscalar(idxs)):
            ret.mat = self.mat.get_col(idxs)
        elif (isinstance(idxs, list)):
            cidxs = idxs
            ret.mat = self.mat.get_cols(cidxs)
        elif (isinstance(idxs, slice)):
            if (is_idx_range_all(idxs)):
                ret.mat = self.mat
            else:
                idxs = normalize_idxs(idxs, self.shape[1])
                ret.mat = self.mat.get_cols(idxs.start, idxs.stop, idxs.step)
        elif (isinstance(idxs, np.ndarray)):
            idxs = np.array(idxs, dtype='l')
            addr = <long *>np.PyArray_DATA(idxs)
            cidxs.assign(addr, addr + len(idxs))
            ret.mat = self.mat.get_cols(cidxs)
        elif (isinstance(idxs, PyMatrix)):
            idx_mat = idxs
            ret.mat = self.mat.get_cols(idx_mat.mat)
        elif (idxs is None):
            if (self.ndim >= 2):
                raise IndexError("doesn't support high dimensional array")
            # If this is a vector, we return a one-col matrix.
            return self.as_matrix()
        else:
            raise ValueError("invalid index")
        ret.init_attr()
        return ret

    def set_rows(self, idxs, vals):
        cdef long *addr
        cdef vector[long] cidxs
        if (isinstance(idxs, xrange)):
            # TODO This isn't a good way of handling xrange.
            idxs = np.array(idxs)
        elif (np.isscalar(idxs)):
            idxs = [idxs]

        cdef PyMatrix rows
        if (isinstance(vals, PyMatrix)):
            rows = vals
        else:
            rows = array(vals)
        if (isinstance(idxs, list)):
            cidxs = idxs
            self.mat = self.mat.set_rows(cidxs, rows.mat)
        elif (isinstance(idxs, slice)):
            if (is_idx_range_all(idxs)):
                if (self.ndim == rows.ndim and self.shape == rows.shape
                        and self.dtype == rows.dtype):
                    self.assign(rows)
                else:
                    raise ValueError("vals doesn't match the shape of this matrix")
            else:
                idxs = normalize_idxs(idxs, self.shape[0])
                self.mat = self.mat.set_rows(idxs.start, idxs.stop, idxs.step, rows.mat)
        elif (isinstance(idxs, np.ndarray)):
            idxs = np.array(idxs, dtype='l')
            addr = <long *>np.PyArray_DATA(idxs)
            cidxs.assign(addr, addr + len(idxs))
            self.mat = self.mat.set_rows(cidxs, rows.mat)
        else:
            raise ValueError("invalid index")
        self.init_attr()

    def set_cols(self, idxs, vals):
        cdef long *addr
        cdef vector[long] cidxs
        if (isinstance(idxs, xrange)):
            # TODO This isn't a good way of handling xrange.
            idxs = np.array(idxs)
        elif (np.isscalar(idxs)):
            idxs = [idxs]

        cdef PyMatrix cols
        if (isinstance(vals, PyMatrix)):
            cols = vals
        else:
            cols = array(vals)
        if (isinstance(idxs, list)):
            cidxs = idxs
            self.mat = self.mat.set_cols(cidxs, cols.mat)
        elif (isinstance(idxs, slice)):
            if (is_idx_range_all(idxs)):
                if (self.ndim == cols.ndim and self.shape == cols.shape
                        and self.dtype == cols.dtype):
                    self.assign(cols)
                else:
                    raise ValueError("vals doesn't match the shape of this matrix")
            else:
                idxs = normalize_idxs(idxs, self.shape[1])
                self.mat = self.mat.set_cols(idxs.start, idxs.stop, idxs.step, cols.mat)
        elif (isinstance(idxs, np.ndarray)):
            idxs = np.array(idxs, dtype='l')
            addr = <long *>np.PyArray_DATA(idxs)
            cidxs.assign(addr, addr + len(idxs))
            self.mat = self.mat.set_cols(cidxs, cols.mat)
        else:
            raise ValueError("invalid index")
        self.init_attr()

    def get_eles(self, row_idxs, col_idxs):
        cdef PyMatrix ret = PyMatrix()
        cdef PyMatrix idxs, arr
        row_idxs = array(row_idxs)
        col_idxs = array(col_idxs)
        # TODO this may not necessary if we have a complete
        # implementation of get_eles().
        if (self.shape[0] > self.shape[1]):
            arr = self.get_rows(row_idxs)
            idxs = concatenate((range(0, len(row_idxs)), col_idxs), axis=1)
        else:
            arr = self.get_cols(col_idxs)
            idxs = concatenate((row_idxs, range(0, len(row_idxs))), axis=1)
        ret.mat = arr.mat.get_eles(idxs.mat)
        ret.init_attr()
        return ret

    def transpose(self):
        if (self.ndim < 2):
            return self

        cdef PyMatrix ret = PyMatrix()
        ret.mat = self.mat.transpose()
        ret.init_attr(self)
        return ret

    def conv_store(self, in_mem, int num_nodes):
        cdef PyMatrix ret = PyMatrix()
        ret.mat = self.mat.conv_store(in_mem, num_nodes)
        ret.init_attr()
        return ret

    def conv_layout(self, string order):
        cdef PyMatrix ret = PyMatrix()
        ret.mat = self.mat.conv_layout(order)
        ret.init_attr()
        return ret

    def cast_ele_type(self, dtype):
        if (not isinstance(dtype, np.dtype)):
            dtype = np.dtype(dtype)
        cdef PyMatrix ret = PyMatrix()
        if (isinstance(dtype, np.dtype)):
            ret.mat = self.mat.cast_ele_type(dtype.char)
        else:
            ret.mat = self.mat.cast_ele_type(dtype.char)
        ret.init_attr()
        return ret

    def assign(self, PyMatrix mat):
        self.mat = mat.mat
        self.init_attr()

    def multiply(self, obj):
        cdef PyMatrix ret = PyMatrix()
        cdef PyMatrix mat
        if (isinstance(obj, PyMatrix)):
            mat = <PyMatrix>obj
        else:
            mat = array(obj)
        ret.mat = self.mat.multiply(mat.mat)
        ret.init_attr()
        return ret

    def as_factor(self, num_levels = -1):
        cdef PyMatrix ret = PyMatrix()
        ret.mat = self.mat.as_factor(num_levels)
        ret.init_attr()
        return ret

    def as_vector(self):
        cdef PyMatrix ret = PyMatrix()
        ret.mat = self.mat.as_vector()
        ret.init_attr()
        return ret

    def as_matrix(self):
        cdef PyMatrix ret = PyMatrix()
        ret.mat = self.mat.as_matrix()
        ret.init_attr()
        return ret

    def cum_(self, op, axis=None, dtype=None, out=None):
        cdef PyMatrix ret = PyMatrix()
        cdef PyMatrix a = self
        if dtype is not None:
            a = a.cast_ele_type(dtype)
        if axis is None:
            raise ValueError("Not support on all elements yet.")
        elif (axis == 0):
            ret = a.cum_col(op)
        elif (axis == 1):
            ret = a.cum_row(op)
        else:
            raise ValueError("invalid axis")
        if out is not None:
            out.assign(ret)
        return ret

    def aggregate_(self, op, axis=None, dtype=None, out=None, keepdims=False):
        cdef PyMatrix ret = PyMatrix()
        cdef PyMatrix a = self
        if dtype is not None:
            a = a.cast_ele_type(dtype)
        if axis is None:
            ret = a.aggregate(op).as_vector()
        elif (axis == 0):
            ret = a.agg_col(op).as_vector()
        elif (axis == 1):
            ret = a.agg_row(op).as_vector()
        else:
            raise ValueError("invalid axis")
        # TODO let's ignore keepdims for now.
        if out is not None:
            out.assign(ret)
        return ret

    # These are generalized functions.

    def inner_prod(self, PyMatrix mat, left_op, right_op):
        cdef PyMatrix ret = PyMatrix()
        ret.mat = self.mat.inner_prod(mat.mat, left_op, right_op)
        ret.init_attr()
        return ret

    def aggregate(self, op):
        cdef PyMatrix ret = PyMatrix()
        ret.mat = self.mat.aggregate(op)
        ret.init_attr()
        return ret

    def agg_row(self, op):
        cdef PyMatrix ret = PyMatrix()
        ret.mat = self.mat.agg_row(op)
        ret.init_attr()
        return ret

    def agg_col(self, op):
        cdef PyMatrix ret = PyMatrix()
        ret.mat = self.mat.agg_col(op)
        ret.init_attr()
        return ret

    def cum_row(self, op):
        cdef PyMatrix ret = PyMatrix()
        ret.mat = self.mat.cum_row(op)
        ret.init_attr()
        return ret

    def cum_col(self, op):
        cdef PyMatrix ret = PyMatrix()
        ret.mat = self.mat.cum_col(op)
        ret.init_attr()
        return ret

    def mapply_rows(self, PyMatrix vec, op):
        cdef PyMatrix ret = PyMatrix()
        ret.mat = self.mat.mapply_rows(vec.mat, op)
        ret.init_attr()
        return ret

    def mapply_cols(self, PyMatrix vec, op):
        cdef PyMatrix ret = PyMatrix()
        ret.mat = self.mat.mapply_cols(vec.mat, op)
        ret.init_attr()
        return ret

    def mapply2(self, obj, op):
        cdef PyMatrix ret = PyMatrix()
        cdef scalar_wrapper var
        cdef PyMatrix mat
        if (isinstance(obj, PyMatrix)):
            mat = <PyMatrix>obj
            ret.mat = self.mat.mapply2(mat.mat, op)
        elif (np.isscalar(obj)):
            if (isinstance(obj, float)):
                var = create_scalar_wrapper[double](obj)
            elif (isinstance(obj, long)):
                var = create_scalar_wrapper[long](obj)
            elif (isinstance(obj, int)):
                var = create_scalar_wrapper[int](obj)
            elif (type(obj) == type(True) or type(obj) == np.bool_):
                var = create_scalar_wrapper[cbool](bool(obj))
            else:
                raise ValueError("invalid scalar type")
            ret.mat = self.mat.apply_scalar(var, op)
        else:
            mat = array(obj)
            ret.mat = self.mat.mapply2(mat.mat, op)
        ret.init_attr()
        return ret

    def sapply(self, op):
        cdef PyMatrix ret = PyMatrix()
        ret.mat = self.mat.sapply(op)
        ret.init_attr()
        return ret

    def groupby(self, op, with_val = True):
        cdef PyMatrix agg = PyMatrix()
        cdef PyMatrix val = PyMatrix()
        cdef pair[matrix_wrapper, matrix_wrapper] res = self.mat.groupby(op,
                with_val)
        if (with_val):
            agg.mat = res.first
            val.mat = res.second
            agg.init_attr()
            val.init_attr()
            return (agg, val)
        else:
            agg.mat = res.first
            agg.init_attr()
            return agg

    def groupby_row(self, labels, op):
        if (not isinstance(labels, PyMatrix)):
            raise ValueError("The labels isn't a PyMatrix")
        cdef PyMatrix label_mat = labels
        cdef PyMatrix ret = PyMatrix()
        ret.mat = self.mat.groupby_row(label_mat.mat, op)
        ret.init_attr()
        return ret

def array(arr, dtype=None, copy=True, order='K'):
    cdef np.ndarray ndarr
    cdef PyMatrix ret = PyMatrix()

    if (order is None):
        order = 'K'
    if (isinstance(arr, PyMatrix)):
        if (dtype is not None):
            arr = arr.cast_ele_type(dtype)
        return arr.copy(order)

    if (isinstance(arr, np.ndarray)):
        ndarr = arr
    else:
        ndarr = np.array(arr)
    if (not ndarr.flags.contiguous):
        ndarr = np.ascontiguousarray(ndarr)

    if ((order == 'K' or order == 'C') and ndarr.flags.c_contiguous):
        order = 'C'
    elif ((order == 'K' or order == 'C') and ndarr.flags.f_contiguous):
        order = 'F'

    # TODO this is a bit too hacky. Is there a better way?
    cdef intptr_t addr = ctypes.c_void_p(ndarr.ctypes.data).value
    if (ndarr.ndim == 1):
        ret.mat = matrix_wrapper(addr, ndarr.shape[0], ndarr.dtype.char)
    elif (ndarr.ndim == 2):
        ret.mat = matrix_wrapper(addr, ndarr.shape[0], ndarr.shape[1],
                ndarr.dtype.char, order)
    else:
        raise ValueError("don't support more than 2 dimensions")

    ret.init_attr()
    if dtype is None:
        return ret
    else:
        return ret.cast_ele_type(dtype)

def empty_like(a, dtype=None, order='K', subok=True):
    cdef PyMatrix ret = PyMatrix()
    shape = a.shape
    if (dtype is None):
        dtype = a.dtype
    elif (not isinstance(dtype, np.dtype)):
        dtype = np.dtype(dtype)

    # TODO what is the input array isn't contiguous.
    if (order == 'K' and a.flags.c_contiguous):
        order = 'C'
    elif (order == 'K' and a.flags.f_contiguous):
        order = 'F'
    if (order != 'C' and order != 'F'):
        order = 'C'

    if (len(shape) == 1):
        ret.mat = matrix_wrapper(shape[0], dtype.char)
    elif (len(shape) == 2):
        ret.mat = matrix_wrapper(shape[0], shape[1], dtype.char, order)
    else:
        raise ValueError("don't support more than 2 dimensions")
    ret.init_attr()
    return ret

def empty(shape, dtype='f', order='C'):
    cdef PyMatrix ret = PyMatrix()
    if (not isinstance(dtype, np.dtype)):
        dtype = np.dtype(dtype)
    if (np.isscalar(shape)):
        ret.mat = matrix_wrapper(shape, dtype.char)
    elif (len(shape) == 1):
        ret.mat = matrix_wrapper(shape[0], dtype.char)
    elif (len(shape) == 2):
        ret.mat = matrix_wrapper(shape[0], shape[1], dtype.char, order)
    else:
        raise ValueError("don't support more than 2 dimensions")
    ret.init_attr()
    return ret

def init_val(PyMatrix data, dtype, val):
    if (np.issubdtype(dtype, float)):
        data.mat.init_const_float(val)
    else:
        data.mat.init_const_int(val)

def create_const(x, shape, order='C'):
    if (isinstance(x, float)):
        dtype = np.dtype('d')
    elif (isinstance(x, long)):
        dtype = np.dtype('l')
    elif (isinstance(x, int)):
        dtype = np.dtype('i')
    else:
        raise ValueError("a scalar with unknown type")
    ret = empty(shape, dtype, order)
    init_val(ret, dtype, x)
    ret.init_attr()
    return ret

def ones(shape, dtype='f', order='C'):
    cdef PyMatrix ret = empty(shape, dtype, order)
    init_val(ret, dtype, 1)
    ret.init_attr()
    return ret

def zeros(shape, dtype='f', order='C'):
    cdef PyMatrix ret = empty(shape, dtype, order)
    init_val(ret, dtype, 0)
    ret.init_attr()
    return ret

def arange(start, stop, step=1, dtype=None):
    cdef size_t l = (stop - start) / step
    cdef PyMatrix ret
    if (isinstance(start, float)):
        ret = empty(l, 'd', order='F')
        ret.mat.init_seq[float](start, step, 0)
    elif (isinstance(start, long)):
        ret = empty(l, 'l', order='F')
        ret.mat.init_seq[long](start, step, 0)
    elif (isinstance(start, int)):
        ret = empty(l, 'i', order='F')
        ret.mat.init_seq[int](start, step, 0)
    else:
        raise ValueError("invalid scalar type")
    ret.init_attr()
    return ret

def average(PyMatrix a, axis=None, weights=None, returned=False):
    if weights is not None and axis is None:
        if (a.shape != weights.shape):
            raise ValueError("weights need to have the same shape as a")
        else:
            a = a * weights
            wsum = np.sum(weights)
    elif weights is not None:
        if (weights.ndim > 1):
            raise ValueError("weights need to be a 1D array")
        elif (axis == 0):
            a = a.mapply_cols(weights, OP_MUL)
        elif (axis == 1):
            a = a.mapply_rows(weights, OP_MUL)
        else:
            raise ValueError("invalid axis")
        wsum = np.sum(weights)
    elif axis is None:
        wsum = a.mat.get_num_rows() * a.mat.get_num_cols()
    else:
        wsum = a.shape[axis]
    if (returned):
        return (np.sum(a, axis)/wsum, wsum)
    else:
        return np.sum(a, axis)/wsum

def dot(a, b, out=None):
    if (isinstance(a, PyMatrix)):
        return a.dot(b, out)
    elif (isinstance(b, PyMatrix)):
        res = b.T.dot(a.T)
        res = res.T
        if (out is not None):
            out.assign(res)
        return res
    else:
        return array(a).dot(b, out)

def sqrt(PyMatrix x, out=None):
    if (out is None):
        return x.sapply(UOP_SQRT)
    else:
        tmp = x.sapply(UOP_SQRT)
        out.assign(tmp)
        return tmp

def absolute(PyMatrix x):
    return x.sapply(UOP_ABS)

def where(PyMatrix condition, x, y):
    cdef PyMatrix ret = PyMatrix()
    cdef PyMatrix xmat
    cdef PyMatrix ymat
    if (np.isscalar(x)):
        xmat = create_const(x, condition.shape)
    elif (isinstance(x, np.ndarray)):
        xmat = array(x)
    else:
        xmat = x
    if (np.isscalar(y)):
        ymat = create_const(y, condition.shape)
    elif (isinstance(y, np.ndarray)):
        ymat = array(y)
    else:
        ymat = y
    ret.mat = condition.mat.ifelse(xmat.mat, ymat.mat)
    ret.init_attr()
    return ret

def maximum(x1, x2, out=None):
    cdef PyMatrix res
    if (isinstance(x1, PyMatrix)):
        res = x1.mapply2(x2, OP_MAX)
    elif (isinstance(x2, PyMatrix)):
        res = x2.mapply2(x1, OP_MAX)
    else:
        raise ValueError("unknown input type")
    if (out is not None):
        out.assign(res)
    return res

def minimum(x1, x2, out=None):
    cdef PyMatrix res
    if (isinstance(x1, PyMatrix)):
        res = x1.mapply2(x2, OP_MIN)
    elif (isinstance(x2, PyMatrix)):
        res = x2.mapply2(x1, OP_MIN)
    else:
        raise ValueError("unknown input type")
    if (out is not None):
        out.assign(res)
    return res

def atleast_1d(arr):
    return array(arr)

def atleast_2d(arr):
    arr = array(arr)
    if (arr.ndim < 2):
        return arr.as_matrix()
    else:
        return arr

def asanyarray(a, dtype=None, order=None):
    return array(a, dtype=dtype, order=order)

def asarray(a, dtype=None, order=None):
    return array(a, dtype=dtype, order=order)

def concatenate(arrs, axis=0):
    cdef vector[matrix_wrapper] mats
    cdef PyMatrix mat
    if (isinstance(arrs, PyMatrix)):
        return arrs
    if (len(arrs) == 1):
        return arrs[0]
    for arr in list(arrs):
        mat = asarray(arr)
        mats.push_back(mat.mat)
    cdef PyMatrix ret = PyMatrix()
    if (axis == 0):
        ret.mat = matrix_wrapper.rbind(mats)
    elif (axis == 1):
        ret.mat = matrix_wrapper.cbind(mats)
    else:
        raise ValueError("don't support axis > 2")
    ret.init_attr()
    return ret

def all(arr, axis=None, out=None, keepdims=False):
    arr = asarray(arr)
    return arr.all(axis, out, keepdims)

def any(arr, axis=None, out=None, keepdims=False):
    arr = asarray(arr)
    return arr.any(axis, out, keepdims)

def sapply(x, uop, out=None, where=True, casting='same_kind', order='K', dtype=None):
    x = asarray(x)
    x = x.sapply(uop)
    if (out is not None):
        out.assign(x)
    if (dtype is not None):
        x = x.cast_ele_type(dtype)
    return x.copy(order)

def sign(x, out=None, where=True, casting='same_kind', order='K', dtype=None):
    return sapply(x, UOP_SIGN, out, where, casting, order, dtype)

def log(x, out=None, where=True, casting='same_kind', order='K', dtype=None):
    return sapply(x, UOP_LOG, out, where, casting, order, dtype)

def log10(x, out=None, where=True, casting='same_kind', order='K', dtype=None):
    return sapply(x, UOP_LOG10, out, where, casting, order, dtype)

def log2(x, out=None, where=True, casting='same_kind', order='K', dtype=None):
    return sapply(x, UOP_LOG2, out, where, casting, order, dtype)

def log1p(x, out=None, where=True, casting='same_kind', order='K', dtype=None):
    return sapply(x + 1, UOP_LOG, out, where, casting, order, dtype)

def exp(x, out=None, where=True, casting='same_kind', order='K', dtype=None):
    x = asarray(x)
    x = pow(create_const(np.exp(1), x.shape), x)
    if (out is not None):
        out.assign(x)
    if (dtype is not None):
        x = x.cast_ele_type(dtype)
    return x.copy(order)

def exp2(x, out=None, where=True, casting='same_kind', order='K', dtype=None):
    x = asarray(x)
    x = pow(create_const(2, x.shape), x)
    if (out is not None):
        out.assign(x)
    if (dtype is not None):
        x = x.cast_ele_type(dtype)
    return x.copy(order)

def ravel(x, order='C'):
    x = asarray(x)
    return x.ravel(order)

def unique(arr, return_index=False, return_inverse=False, return_counts=False, axis=None):
    cdef PyMatrix x = asarray(arr)
    if (return_index):
        raise NotImplementedError("Not support return index yet")
    if (return_inverse):
        raise NotImplementedError("Not support return inverse yet")
    if (axis is not None):
        raise NotImplementedError("Only support computing unique elements")

    cdef pair[matrix_wrapper, matrix_wrapper] mats = x.mat.groupby(AGG_COUNT, True)
    cdef PyMatrix ret1 = PyMatrix()
    cdef PyMatrix ret2 = PyMatrix()
    if (return_counts):
        ret1.mat = mats.second
        ret1.init_attr()
        ret2.mat = mats.first
        ret2.init_attr()
        return ret1, ret2
    else:
        ret1.mat = mats.second
        ret1.init_attr()
        return ret1

def squeeze(a, axis=None):
    a = asarray(a)
    # If this is a one-row or one-col matrix, we should convert it to
    # a vector.
    return a.ravel()

def isfinite(x, out=None, where=True, casting='same_kind', order='K', dtype=None):
    return None

def init_flashpy(conf_file=""):
    return init_flashpy_c(conf_file)
