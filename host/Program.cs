using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using static System.Diagnostics.Debug;


using Microsoft.Quantum.Simulation.Core;
using Microsoft.Quantum.Simulation.Simulators;

namespace ISBN
{
    class Program
    {
        static async Task Main(string[] args)
        {
            using var sim = new QuantumSimulator();

            var inputBSN = new long[] {0, 3, 0, 6, -1, 0, 6, 1, 5, 2};
            var QinputBSN = new QArray<long>(inputBSN);
            var ISBNConstants = GetIsbnCheckConstants(inputBSN);
            var interations = GetInterations(inputBSN.Length);
            var test = await SearchForMissingDigit.Run(sim,QinputBSN, ISBNConstants,interations);
            Console.WriteLine("Hello World!");
            Console.WriteLine($"return test: {test}");

            (int,int) GetIsbnCheckConstants(long[] digits){
                if(digits.Length != 10){
                    throw new ArgumentException("ISBN need to be 10 digits");
                }
                var a =0;
                var b =0;
                var index = 0;
                foreach (var digit in digits)
                {
                    if(digit < 0 ){
                        a = 10 - index;
                    }else{
                        b += (10 - index) * (int)digit;
                    }
                    index++;
                }
                return (a, b % 11);
            }


            int GetInterations(int nItems){
                var angle = Math.Asin(1 / Math.Sqrt((double)nItems));
                var nIterations = Math.Round(0.25 * Math.PI / angle - 0.5);
                return (int)nIterations;
            }

        }
    }
}
