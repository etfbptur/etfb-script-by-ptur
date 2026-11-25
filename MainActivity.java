package com.example.kalkulatorkeren;

import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import androidx.appcompat.app.AppCompatActivity;
import com.example.kalkulatorkeren.databinding.ActivityMainBinding;

public class MainActivity extends AppCompatActivity {

    private ActivityMainBinding binding;
    private StringBuilder currentInput = new StringBuilder();
    private double operand1 = Double.NaN;
    private char pendingOperator = '\0';
    private boolean resetDisplay = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityMainBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        setNumericButtonListeners();
        setOperatorButtonListeners();
        binding.btnClear.setOnClickListener(v -> clearAll());
        binding.btnEquals.setOnClickListener(v -> calculateResult());
    }

    private void setNumericButtonListeners() {
        View.OnClickListener listener = v -> {
            if (resetDisplay) {
                currentInput.setLength(0);
                resetDisplay = false;
            }
            Button b = (Button) v;
            currentInput.append(b.getText());
            updateDisplay();
        };

        binding.btn0.setOnClickListener(listener);
        binding.btn1.setOnClickListener(listener);
        binding.btn2.setOnClickListener(listener);
        binding.btn3.setOnClickListener(listener);
        binding.btn4.setOnClickListener(listener);
        binding.btn5.setOnClickListener(listener);
        binding.btn6.setOnClickListener(listener);
        binding.btn7.setOnClickListener(listener);
        binding.btn8.setOnClickListener(listener);
        binding.btn9.setOnClickListener(listener);
        binding.btnDot.setOnClickListener(listener);
    }

    private void setOperatorButtonListeners() {
        View.OnClickListener opListener = v -> {
            Button b = (Button) v;
            char op = b.getText().charAt(0);
            if (currentInput.length() == 0 && Double.isNaN(operand1)) {
                // No operand yet, ignore
                return;
            }
            if (!Double.isNaN(operand1) && !resetDisplay) {
                calculateResult();
            } else {
                operand1 = Double.parseDouble(currentInput.toString());
            }
            pendingOperator = op;
            resetDisplay = true;
        };

        binding.btnAdd.setOnClickListener(opListener);
        binding.btnSub.setOnClickListener(opListener);
        binding.btnMul.setOnClickListener(opListener);
        binding.btnDiv.setOnClickListener(opListener);
    }

    private void calculateResult() {
        if (pendingOperator == '\0' || currentInput.length() == 0) {
            return;
        }
        double operand2 = Double.parseDouble(currentInput.toString());
        double result = 0;
        switch (pendingOperator) {
            case '+':
                result = operand1 + operand2;
                break;
            case '-':
                result = operand1 - operand2;
                break;
            case '*':
                result = operand1 * operand2;
                break;
            case '/':
                if (operand2 != 0) {
                    result = operand1 / operand2;
                } else {
                    binding.tvDisplay.setText("Error");
                    clearAll();
                    return;
                }
                break;
        }
        operand1 = result;
        currentInput.setLength(0);
        currentInput.append(removeTrailingZero(result));
        updateDisplay();
        pendingOperator = '\0';
        resetDisplay = true;
    }

    private void clearAll() {
        currentInput.setLength(0);
        operand1 = Double.NaN;
        pendingOperator = '\0';
        resetDisplay = false;
        updateDisplay();
    }

    private void updateDisplay() {
        if (currentInput.length() == 0) {
            binding.tvDisplay.setText("0");
        } else {
            binding.tvDisplay.setText(currentInput.toString());
        }
    }

    private String removeTrailingZero(double value) {
        if (value == (long) value) {
            return String.format("%d", (long) value);
        } else {
            return String.valueOf(value);
        }
    }
}