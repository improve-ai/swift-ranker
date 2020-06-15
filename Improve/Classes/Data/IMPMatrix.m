//
//  IMPMatrix.m
//  ImproveUnitTests
//
//  Created by Vladimir on 2/5/20.
//

#import "IMPMatrix.h"


@implementation IMPMatrix

- (void)dealloc
{
    if (_buffer != 0) {
        free(_buffer);
    }
}

- (instancetype)initWithRows:(NSUInteger)rows columns:(NSUInteger)columns
{
    return [self initWithRows:rows columns:columns initialValue:NAN];
}

- (instancetype)initWithRows:(NSUInteger)rows
                     columns:(NSUInteger)columns
                initialValue:(double)initialValue
{
    self = [super init];
    if (self) {
        _rows = rows;
        _columns = columns;
        NSUInteger count = rows * columns;
        _buffer = calloc(count, sizeof(double));
        for (NSUInteger i = 0; i < count; i++) {
            _buffer[i] = initialValue;
        }
    }
    return self;
}

- (double)valueAtRow:(NSUInteger)row column:(NSUInteger)column
{
    if (row < 0 || row >= self.rows
        || column < 0 || column >= self.columns)
    {
        [self raiseOutOfBoundsException];
    }

    return *(_buffer + column + row * _columns);
}

- (void)setValue:(double)value atRow:(NSUInteger)row column:(NSUInteger)column
{
    if (row < 0 || row >= self.rows
        || column < 0 || column >= self.columns)
    {
        [self raiseOutOfBoundsException];
    }
    *(_buffer + column + row * _columns) = value;
}

- (NSArray *)NSArray
{
    NSMutableArray *a2DArray = [NSMutableArray arrayWithCapacity:self.rows];

    for (NSUInteger row = 0; row < self.rows; row++)
    {
        NSMutableArray *rowArray = [NSMutableArray arrayWithCapacity:self.columns];
        [a2DArray addObject:rowArray];
        for (NSUInteger col = 0; col < self.columns; col++)
        {
            [rowArray addObject:[NSNumber numberWithDouble:[self valueAtRow:row column:col]]];
        }
    }

    return a2DArray;
}

- (void)raiseOutOfBoundsException
{
    NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException reason:@"Column or row is out of matrix bounds." userInfo:nil];
    [exception raise];
}

@end
