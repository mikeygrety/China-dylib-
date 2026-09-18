//
//  AVX512ViewEditorController.m
//  AVX512 / MRzefv
//
//  Live editor for the UIView selected by AVX512.
//  The editor mutates the target view directly and records
//  operations for the later MRzefvGenerated dylib.
//
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#pragma mark - Operation Model
typedef NS_ENUM(NSInteger, AVX512EditOperationType) {
    AVX512EditOperationMove,
    AVX512EditOperationResize,
    AVX512EditOperationReplaceText,
    AVX512EditOperationAddText,
    AVX512EditOperationSetHidden,
    AVX512EditOperationReplaceImage
};
@interface AVX512EditOperation : NSObject
@property (nonatomic, assign) AVX512EditOperationType type;
@property (nonatomic, copy) NSString *className;
@property (nonatomic, copy) NSString *viewPath;
@property (nonatomic, strong) NSDictionary *values;
@end
@implementation AVX512EditOperation
@end
#pragma mark - Editor
@interface AVX512ViewEditorController : UIViewController
@property (nonatomic, weak) UIView *targetView;
@property (nonatomic, strong) NSMutableArray<AVX512EditOperation *> *operations;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *classLabel;
@property (nonatomic, strong) UISwitch *hiddenSwitch;
@property (nonatomic, strong) UIButton *moveButton;
@property (nonatomic, strong) UIButton *resizeButton;
@property (nonatomic, strong) UIButton *textButton;
@property (nonatomic, strong) UIButton *addTextButton;
@property (nonatomic, strong) UIButton *imageButton;
@property (nonatomic, strong) UIButton *previewButton;
@property (nonatomic, strong) UIButton *generateButton;
- (instancetype)initWithTargetView:(UIView *)view;
@end
#pragma mark - Implementation
@implementation AVX512ViewEditorController
- (instancetype)initWithTargetView:(UIView *)view
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _targetView = view;
        _operations = [NSMutableArray array];
    }
    return self;
}
#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor =
        [UIColor systemBackgroundColor];
    [self buildInterface];
    [self refreshTargetInformation];
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self refreshTargetInformation];
}
#pragma mark - Interface
- (void)buildInterface
{
    self.titleLabel =
        [[UILabel alloc] init];
    self.titleLabel.font =
        [UIFont preferredFontForTextStyle:
            UIFontTextStyleHeadline];
    self.titleLabel.text =
        @"Edit View";
    self.classLabel =
        [[UILabel alloc] init];
    self.classLabel.font =
        [UIFont monospacedSystemFontOfSize:12
                                    weight:UIFontWeightRegular];
    self.classLabel.textColor =
        [UIColor secondaryLabelColor];
    self.classLabel.numberOfLines = 0;
    UIStackView *header =
        [[UIStackView alloc]
            initWithArrangedSubviews:@[
                self.titleLabel,
                self.classLabel
            ]];
    header.axis = UILayoutConstraintAxisVertical;
    header.spacing = 4.0;
    self.scrollView =
        [[UIScrollView alloc] init];
    self.stackView =
        [[UIStackView alloc] init];
    self.stackView.axis =
        UILayoutConstraintAxisVertical;
    self.stackView.spacing = 12.0;
    self.stackView.layoutMargins =
        UIEdgeInsetsMake(20, 20, 32, 20);
    self.stackView.layoutMarginsRelativeArrangement = YES;
    [self.scrollView addSubview:self.stackView];
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.stackView.topAnchor
            constraintEqualToAnchor:
                self.scrollView.contentLayoutGuide.topAnchor],
        [self.stackView.bottomAnchor
            constraintEqualToAnchor:
                self.scrollView.contentLayoutGuide.bottomAnchor],
        [self.stackView.leadingAnchor
            constraintEqualToAnchor:
                self.scrollView.contentLayoutGuide.leadingAnchor],
        [self.stackView.trailingAnchor
            constraintEqualToAnchor:
                self.scrollView.contentLayoutGuide.trailingAnchor],
        [self.stackView.widthAnchor
            constraintEqualToAnchor:
                self.scrollView.frameLayoutGuide.widthAnchor]
    ]];
    UIStackView *root =
        [[UIStackView alloc]
            initWithArrangedSubviews:@[
                header,
                self.scrollView
            ]];
    root.axis = UILayoutConstraintAxisVertical;
    root.spacing = 12.0;
    root.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:root];
    [NSLayoutConstraint activateConstraints:@[
        [root.topAnchor
            constraintEqualToAnchor:
                self.view.safeAreaLayoutGuide.topAnchor],
        [root.bottomAnchor
            constraintEqualToAnchor:
                self.view.bottomAnchor],
        [root.leadingAnchor
            constraintEqualToAnchor:
                self.view.leadingAnchor],
        [root.trailingAnchor
            constraintEqualToAnchor:
                self.view.trailingAnchor]
    ]];
    [self addSectionTitle:@"Visibility"];
    self.hiddenSwitch =
        [[UISwitch alloc] init];
    self.hiddenSwitch.on =
        self.targetView.hidden;
    [self.hiddenSwitch
        addTarget:self
           action:@selector(hiddenChanged:)
 forControlEvents:UIControlEventValueChanged];
    [self addRowWithTitle:@"Hidden"
                   control:self.hiddenSwitch];
    [self addSectionTitle:@"Geometry"];
    self.moveButton =
        [self actionButton:@"Move"];
    [self.moveButton
        addTarget:self
           action:@selector(moveTapped:)
 forControlEvents:UIControlEventTouchUpInside];
    [self addButton:self.moveButton];
    self.resizeButton =
        [self actionButton:@"Resize"];
    [self.resizeButton
        addTarget:self
           action:@selector(resizeTapped:)
 forControlEvents:UIControlEventTouchUpInside];
    [self addButton:self.resizeButton];
    [self addSectionTitle:@"Content"];
    self.textButton =
        [self actionButton:@"Replace Text"];
    [self.textButton
        addTarget:self
           action:@selector(replaceTextTapped:)
 forControlEvents:UIControlEventTouchUpInside];
    [self addButton:self.textButton];
    self.addTextButton =
        [self actionButton:@"Add Text"];
    [self.addTextButton
        addTarget:self
           action:@selector(addTextTapped:)
 forControlEvents:UIControlEventTouchUpInside];
    [self addButton:self.addTextButton];
    self.imageButton =
        [self actionButton:@"Replace Image / Icon"];
    [self.imageButton
        addTarget:self
           action:@selector(imageTapped:)
 forControlEvents:UIControlEventTouchUpInside];
    [self addButton:self.imageButton];
    [self addSectionTitle:@"Build"];
    self.previewButton =
        [self actionButton:@"Preview"];
    [self.previewButton
        addTarget:self
           action:@selector(previewTapped:)
 forControlEvents:UIControlEventTouchUpInside];
    [self addButton:self.previewButton];
    self.generateButton =
        [self actionButton:@"Generate MRzefv Dylib"];
    [self.generateButton
        addTarget:self
           action:@selector(generateTapped:)
 forControlEvents:UIControlEventTouchUpInside];
    [self addButton:self.generateButton];
}
#pragma mark - UI Helpers
- (void)addSectionTitle:(NSString *)title
{
    UILabel *label =
        [[UILabel alloc] init];
    label.text = title;
    label.font =
        [UIFont preferredFontForTextStyle:
            UIFontTextStyleSubheadline];
    label.textColor =
        [UIColor secondaryLabelColor];
    [self.stackView addArrangedSubview:label];
}
- (void)addButton:(UIButton *)button
{
    button.heightAnchor.constraintGreaterThanOrEqualToConstant:
        46.0].active = YES;
    [self.stackView addArrangedSubview:button];
}
- (UIButton *)actionButton:(NSString *)title
{
    UIButton *button =
        [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title
            forState:UIControlStateNormal];
    button.titleLabel.font =
        [UIFont preferredFontForTextStyle:
            UIFontTextStyleBody];
    button.contentHorizontalAlignment =
        UIControlContentHorizontalAlignmentLeft;
    button.configuration =
        [UIButtonConfiguration
            borderedProminentButtonConfiguration];
    return button;
}
- (void)addRowWithTitle:(NSString *)title
                control:(UIView *)control
{
    UILabel *label =
        [[UILabel alloc] init];
    label.text = title;
    UIStackView *row =
        [[UIStackView alloc]
            initWithArrangedSubviews:@[
                label,
                control
            ]];
    row.axis =
        UILayoutConstraintAxisHorizontal;
    row.alignment =
        UIStackViewAlignmentCenter;
    row.distribution =
        UIStackViewDistributionFill;
    [self.stackView addArrangedSubview:row];
}
#pragma mark - Information
- (void)refreshTargetInformation
{
    if (!self.targetView) {
        self.classLabel.text =
            @"Target unavailable";
        return;
    }
    Class cls =
        object_getClass(self.targetView);
    NSString *className =
        NSStringFromClass(cls);
    CGRect frame =
        self.targetView.frame;
    self.classLabel.text =
        [NSString stringWithFormat:
            @"%@\nframe: %@",
            className,
            NSStringFromCGRect(frame)];
}
#pragma mark - Visibility
- (void)hiddenChanged:(UISwitch *)sender
{
    if (!self.targetView) {
        return;
    }
    self.targetView.hidden =
        sender.isOn;
    [self recordOperation:
        AVX512EditOperationSetHidden
                    values:@{
        @"hidden": @(sender.isOn)
    }];
}
#pragma mark - Move
- (void)moveTapped:(UIButton *)sender
{
    if (!self.targetView) {
        return;
    }
    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:@"Move View"
                             message:@"Enter X and Y coordinates."
                      preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"X";
        field.keyboardType =
            UIKeyboardTypeDecimalPad;
        field.text =
            [NSString stringWithFormat:@"%.1f",
                self.targetView.frame.origin.x];
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"Y";
        field.keyboardType =
            UIKeyboardTypeDecimalPad;
        field.text =
            [NSString stringWithFormat:@"%.1f",
                self.targetView.frame.origin.y];
    }];
    __weak typeof(self) weakSelf = self;
    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Cancel"
                      style:UIAlertActionStyleCancel
                    handler:nil]];
    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Apply"
                      style:UIAlertActionStyleDefault
                    handler:^(UIAlertAction *action) {
        __strong typeof(weakSelf) self = weakSelf;
        CGFloat x =
            [alert.textFields[0].text doubleValue];
        CGFloat y =
            [alert.textFields[1].text doubleValue];
        CGRect frame =
            self.targetView.frame;
        frame.origin =
            CGPointMake(x, y);
        self.targetView.frame = frame;
        [self recordOperation:
            AVX512EditOperationMove
                        values:@{
            @"x": @(x),
            @"y": @(y)
        }];
        [self refreshTargetInformation];
    }]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}
#pragma mark - Resize
- (void)resizeTapped:(UIButton *)sender
{
    if (!self.targetView) {
        return;
    }
    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:@"Resize View"
                             message:@"Enter width and height."
                      preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"Width";
        field.keyboardType =
            UIKeyboardTypeDecimalPad;
        field.text =
            [NSString stringWithFormat:@"%.1f",
                self.targetView.bounds.size.width];
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"Height";
        field.keyboardType =
            UIKeyboardTypeDecimalPad;
        field.text =
            [NSString stringWithFormat:@"%.1f",
                self.targetView.bounds.size.height];
    }];
    __weak typeof(self) weakSelf = self;
    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Cancel"
                      style:UIAlertActionStyleCancel
                    handler:nil]];
    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Apply"
                      style:UIAlertActionStyleDefault
                    handler:^(UIAlertAction *action) {
        __strong typeof(weakSelf) self = weakSelf;
        CGFloat width =
            [alert.textFields[0].text doubleValue];
        CGFloat height =
            [alert.textFields[1].text doubleValue];
        if (width <= 0 || height <= 0) {
            return;
        }
        CGRect bounds =
            self.targetView.bounds;
        bounds.size =
            CGSizeMake(width, height);
        self.targetView.bounds = bounds;
        [self recordOperation:
            AVX512EditOperationResize
                        values:@{
            @"width": @(width),
            @"height": @(height)
        }];
        [self refreshTargetInformation];
    }]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}
#pragma mark - Text
- (void)replaceTextTapped:(UIButton *)sender
{
    [self presentTextEditor:NO];
}
- (void)addTextTapped:(UIButton *)sender
{
    [self presentTextEditor:YES];
}
- (void)presentTextEditor:(BOOL)addText
{
    if (!self.targetView) {
        return;
    }
    NSString *currentText =
        [self textValueForView:self.targetView];
    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:
                addText ? @"Add Text" : @"Replace Text"
                             message:nil
                      preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"Text";
        if (!addText) {
            field.text = currentText;
        }
    }];
    __weak typeof(self) weakSelf = self;
    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Cancel"
                      style:UIAlertActionStyleCancel
                    handler:nil]];
    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Apply"
                      style:UIAlertActionStyleDefault
                    handler:^(UIAlertAction *action) {
        __strong typeof(weakSelf) self = weakSelf;
        NSString *text =
            alert.textFields.firstObject.text ?: @"";
        if (addText) {
            UILabel *label =
                [[UILabel alloc]
                    initWithFrame:
                        CGRectMake(0, 0, 160, 40)];
            label.text = text;
            label.textColor =
                [UIColor labelColor];
            [self.targetView addSubview:label];
            [self recordOperation:
                AVX512EditOperationAddText
                            values:@{
                @"text": text
            }];
        } else {
            if ([self.targetView
                    respondsToSelector:@selector(setText:)]) {
                [(id)self.targetView setText:text];
            } else {
                return;
            }
            [self recordOperation:
                AVX512EditOperationReplaceText
                            values:@{
                @"text": text
            }];
        }
        [self refreshTargetInformation];
    }]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}
- (NSString *)textValueForView:(UIView *)view
{
    if ([view respondsToSelector:@selector(text)]) {
        id value =
            [(id)view text];
        if ([value isKindOfClass:[NSString class]]) {
            return value;
        }
    }
    return @"";
}
#pragma mark - Image
- (void)imageTapped:(UIButton *)sender
{
    if (!self.targetView) {
        return;
    }
    /*
     The actual image picker/resource importer will be connected
     here. For now the operation is represented explicitly so the
     generated manifest has a stable operation type.
     */
    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:@"Replace Image / Icon"
                             message:
                @"Choose an image resource in the AVX512 resource picker."
                      preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Cancel"
                      style:UIAlertActionStyleCancel
                    handler:nil]];
    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Record Resource"
                      style:UIAlertActionStyleDefault
                    handler:^(UIAlertAction *action) {
        [self recordOperation:
            AVX512EditOperationReplaceImage
                        values:@{
            @"resource": @"__RESOURCE_FILE__"
        }];
    }]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}
#pragma mark - Preview
- (void)previewTapped:(UIButton *)sender
{
    if (!self.targetView) {
        return;
    }
    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:@"Preview"
                             message:
                @"The current live changes are already applied to the target view."
                      preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Done"
                      style:UIAlertActionStyleDefault
                    handler:nil]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}
#pragma mark - Generate
- (void)generateTapped:(UIButton *)sender
{
    if (self.operations.count == 0) {
        UIAlertController *alert =
            [UIAlertController
                alertControllerWithTitle:@"No Changes"
                                 message:
                    @"Make at least one live edit before generating the MRzefv dylib."
                          preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:
            [UIAlertAction
                actionWithTitle:@"OK"
                          style:UIAlertActionStyleDefault
                        handler:nil]];
        [self presentViewController:alert
                           animated:YES
                         completion:nil];
        return;
    }
    /*
     The next build-generation layer consumes self.operations
     and produces:
       Sources/MRzefvGenerated.h
       Sources/MRzefvGenerated.m
       manifest.json
       build.sh
       workflow
     The editor itself does not compile or sign anything.
     */
    NSDictionary *summary = @{
        @"class":
            NSStringFromClass(object_getClass(self.targetView)) ?: @"UIView",
        @"operationCount":
            @(self.operations.count)
    };
    NSLog(@"[AVX512] Generate requested: %@", summary);
    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:@"Generate MRzefv Dylib"
                             message:
                @"The recorded operations are ready for the generated build package."
                      preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"Continue"
                      style:UIAlertActionStyleDefault
                    handler:nil]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}
#pragma mark - Operation Recording
- (void)recordOperation:(AVX512EditOperationType)type
                 values:(NSDictionary *)values
{
    if (!self.targetView) {
        return;
    }
    AVX512EditOperation *operation =
        [[AVX512EditOperation alloc] init];
    operation.type = type;
    operation.className =
        NSStringFromClass(
            object_getClass(self.targetView));
    operation.viewPath =
        [self viewPathForView:self.targetView];
    operation.values =
        values ?: @{};
    [self.operations addObject:operation];
    NSLog(@"[AVX512] Recorded operation %ld: %@",
          (long)type,
          operation.values);
}
#pragma mark - View Path
- (NSString *)viewPathForView:(UIView *)view
{
    if (!view) {
        return @"";
    }
    NSMutableArray<NSString *> *components =
        [NSMutableArray array];
    UIView *current = view;
    while (current) {
        UIView *superview =
            current.superview;
        NSUInteger index = 0;
        if (superview) {
            index =
                [superview.subviews indexOfObjectIdenticalTo:current];
        }
        NSString *component =
            [NSString stringWithFormat:
                @"%@[%lu]",
                NSStringFromClass(
                    object_getClass(current)),
                (unsigned long)index];
        [components insertObject:component
                         atIndex:0];
        current = superview;
        if (components.count > 100) {
            break;
        }
    }
    return [components componentsJoinedByString:@"/"];
}
@end