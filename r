using System;
using System.Windows.Forms;
using MathNet.Symbolics;
using OxyPlot;
using OxyPlot.Series;
using OxyPlot.WindowsForms;
using OxyPlot.Axes;
using System.Linq;
using System.Text.RegularExpressions;

namespace CoordinateDescent
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new CoordinateDescent());
        }
    }

    public class CoordinateDescent : Form
    {
        private TextBox textBoxA;
        private TextBox textBoxB;
        private TextBox textBoxE;
        private Button calculateButton;
        private Button clearButton;
        private Label labelA;
        private Label labelB;
        private Label labelE;
        private TextBox localPointsTextBox;
        private PlotView plotView;

        private TextBox textBoxFunction;
        private Label labelFunction;

        public CoordinateDescent()
        {
            InitializeComponents();
            this.Size = new System.Drawing.Size(1000, 800);
        }

        private void InitializeComponents()
        {
            Panel mainPanel = new Panel();
            mainPanel.Dock = DockStyle.Fill;
            this.Controls.Add(mainPanel);

            labelFunction = new Label();
            labelFunction.Text = "функция";
            labelFunction.Location = new System.Drawing.Point(570, 10);
            labelFunction.AutoSize = true;
            mainPanel.Controls.Add(labelFunction);

            textBoxFunction = new TextBox();
            textBoxFunction.Location = new System.Drawing.Point(labelFunction.Right + 5, 10);
            textBoxFunction.Size = new System.Drawing.Size(200, 20);
            mainPanel.Controls.Add(textBoxFunction);

            labelA = new Label();
            labelA.Text = "a";
            labelA.Location = new System.Drawing.Point(500, 70);
            labelA.AutoSize = true;
            mainPanel.Controls.Add(labelA);

            textBoxA = new TextBox();
            textBoxA.Location = new System.Drawing.Point(labelA.Right + 5, 70);
            textBoxA.Size = new System.Drawing.Size(100, 20);
            mainPanel.Controls.Add(textBoxA);

            labelB = new Label();
            labelB.Text = "b";
            labelB.Location = new System.Drawing.Point(textBoxA.Right + 10, 70);
            labelB.AutoSize = true;
            mainPanel.Controls.Add(labelB);

            textBoxB = new TextBox();
            textBoxB.Location = new System.Drawing.Point(labelB.Right + 5, 70);
            textBoxB.Size = new System.Drawing.Size(100, 20);
            mainPanel.Controls.Add(textBoxB);

            labelE = new Label();
            labelE.Text = "e(точность)";
            labelE.Location = new System.Drawing.Point(textBoxB.Right + 10, 70);
            labelE.AutoSize = true;
            mainPanel.Controls.Add(labelE);

            textBoxE = new TextBox();
            textBoxE.Location = new System.Drawing.Point(labelE.Right + 5, 70);
            textBoxE.Size = new System.Drawing.Size(100, 20);
            mainPanel.Controls.Add(textBoxE);

            calculateButton = new Button();
            calculateButton.Text = "рассчитать";
            calculateButton.Location = new System.Drawing.Point(calculateButton.Left + calculateButton.Width + 10, 10);
            calculateButton.Click += new System.EventHandler(this.CalculateButton_Click);
            mainPanel.Controls.Add(calculateButton);

            clearButton = new Button();
            clearButton.Text = "очистить";
            clearButton.Location = new System.Drawing.Point(10, 10);
            clearButton.Click += new System.EventHandler(this.ClearButton_Click);
            mainPanel.Controls.Add(clearButton);

            localPointsTextBox = new TextBox();
            localPointsTextBox.Multiline = true;
            localPointsTextBox.ScrollBars = ScrollBars.Vertical;
            localPointsTextBox.Location = new System.Drawing.Point(10, 50);
            localPointsTextBox.Size = new System.Drawing.Size(300, 100);
            mainPanel.Controls.Add(localPointsTextBox);

            int graphHeight = 550;

            Panel graphContainer = new Panel();
            graphContainer.Dock = DockStyle.Bottom;
            graphContainer.Height = graphHeight;
            mainPanel.Controls.Add(graphContainer);

            plotView = new PlotView();
            plotView.Dock = DockStyle.Fill;
            graphContainer.Controls.Add(plotView);
        }

        private void CalculateButton_Click(object sender, EventArgs e)
        {
            if (!double.TryParse(textBoxA.Text.Replace(",", "."), System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out double a) ||
                !double.TryParse(textBoxB.Text.Replace(",", "."), System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out double b) ||
                !double.TryParse(textBoxE.Text.Replace(",", "."), System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out double enteredValue))
            {
                MessageBox.Show("введите корректные числовые значения");
                return;
            }

            if (enteredValue < 0)
            {
                throw new ArgumentException("e >= 0");
            }

            double calculatedEpsilon = enteredValue >= 0 ? Math.Pow(10, -enteredValue) : enteredValue;

            if (a > b)
            {
                throw new ArgumentException("a < b");
            }

            string functionText = textBoxFunction.Text;

            Func<double, double> originalFunction = x =>
            {
                var expression = SymbolicExpression.Parse(functionText).Compile("x").Invoke(x);
                return Convert.ToDouble(expression.ToString());
            };

            double result = CoordinateDescentUpdate(originalFunction, calculatedEpsilon, a, b);

            double localMin = FindMinimum(a, b, originalFunction, calculatedEpsilon);
            double localMax = FindMaximum(a, b, originalFunction, calculatedEpsilon);

            localPointsTextBox.Text = $"минимум {localMin}\r\n " +
                                      $"максимум {localMax}";

            var plotModel = new PlotModel();

            var xAxis = new LinearAxis { Position = AxisPosition.Bottom, Title = "X" };
            var yAxis = new LinearAxis { Position = AxisPosition.Left, Title = "Y" };

            xAxis.MajorGridlineStyle = LineStyle.Solid;
            yAxis.MajorGridlineStyle = LineStyle.Solid;

            plotModel.Axes.Add(xAxis);
            plotModel.Axes.Add(yAxis);

            var seriesPositive = new LineSeries
            {
                Color = OxyColors.Green 
            };
            var seriesNegative = new LineSeries
            {
                Color = OxyColors.Red 
            };

            for (double x = 0.01; x <= b; x += 0.1)
            {
                seriesPositive.Points.Add(new OxyPlot.DataPoint(x, originalFunction(x)));
            }

            for (double x = -0.01; x >= a; x -= 0.1)
            {
                seriesNegative.Points.Add(new OxyPlot.DataPoint(x, originalFunction(x)));
            }

            plotModel.Series.Add(seriesPositive);
            plotModel.Series.Add(seriesNegative);

            plotModel.Annotations.Add(new OxyPlot.Annotations.PointAnnotation
            {
                X = localMin,
                Y = originalFunction(localMin),
                Text = "минимум",
                TextPosition = new DataPoint(localMin, originalFunction(localMin) - 0.5),
                TextColor = OxyColors.Red
            });

            plotModel.Annotations.Add(new OxyPlot.Annotations.PointAnnotation
            {
                X = localMax,
                Y = originalFunction(localMax),
                Text = "максимум",
                TextPosition = new DataPoint(localMax, originalFunction(localMax) + 0.5),
                TextColor = OxyColors.Blue
            });

            plotView.Model = plotModel;
        }

        // использовали только значения функции для определения направления движения.
        private double CoordinateDescentUpdate(Func<double, double> function, double a, double b, double epsilon)
        {
            // Начальное значение x в середине интервала [a, b]
            double x = (a + b) / 2.0;

            // Максимальное число итераций для предотвращения зацикливания
            int maxIterations = 2000;

            // Цикл итераций метода координатного спуска
            for (int i = 0; i < maxIterations; i++)
            {
                // Значение функции в точке x
                double fx = function(x);

                // Значение функции в соседних точках
                double fxPlusEpsilon = function(x + epsilon);
                double fxMinusEpsilon = function(x - epsilon);

                // Определение направления движения в пространстве поиска
                double direction = fxPlusEpsilon - fxMinusEpsilon;

                // Обновление границ интервала в зависимости от направления движения
                if (direction > 0)
                {
                    // Если двигаемся вверх, сдвигаем правую границу интервала
                    b = x;
                }
                else if (direction < 0)
                {
                    // Если двигаемся вниз, сдвигаем левую границу интервала
                    a = x;
                }
                else
                {
                    // Если направление близко к нулю, считаем это минимумом/максимумом и завершаем цикл
                    break;
                }

                // Обновление значения x в середине нового интервала
                x = (a + b) / 2.0;

                // Проверка критерия сходимости: если интервал слишком мал, завершаем цикл
                if (Math.Abs(b - a) < epsilon)
                {
                    break;
                }
            }

            // Возвращаем найденное значение x
            return x;
        }

        // Метод для поиска минимума функции на заданном интервале
        private double FindMinimum(double a, double b, Func<double, double> function, double epsilon)
        {
            // Вызываем метод координатного спуска для поиска минимума
            return CoordinateDescentUpdate(function, a, b, epsilon);
        }

        // Метод для поиска максимума функции на заданном интервале
        private double FindMaximum(double a, double b, Func<double, double> function, double epsilon)
        {
            // Вызываем метод координатного спуска для поиска максимума, инвертируя знак функции
            return CoordinateDescentUpdate(x => -function(x), a, b, epsilon);
        }

        private void ClearButton_Click(object sender, EventArgs e)
        {
            textBoxA.Clear();
            textBoxB.Clear();
            textBoxE.Clear();
            textBoxFunction.Clear();
            localPointsTextBox.Text = string.Empty;
        }
    }
}
