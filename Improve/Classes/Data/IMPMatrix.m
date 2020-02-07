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
    self = [super init];
    if (self) {
        _rows = rows;
        _columns = columns;
        _buffer = calloc(rows * columns, sizeof(double));
    }
    return self;
}

- (double)valueAtRow:(NSUInteger)row column:(NSUInteger)column
{
    return *(_buffer + column + row * _columns);
}

- (void)setValue:(double)value atRow:(NSUInteger)row column:(NSUInteger)column
{
    *(_buffer + column + row * _columns) = value;
}

- (NSArray *)aNSArray
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

@end
