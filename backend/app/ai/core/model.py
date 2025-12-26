import torch
import torch.nn as nn


class SkeletonLSTM(nn.Module):
    def __init__(
        self,
        num_class=2,
        in_channels=3,
        num_joints=33,
        hidden_size=128,
        num_layers=2,
        dropout=0.3,
    ):
        super().__init__()

        input_size = num_joints * in_channels

        self.bn_input = nn.BatchNorm1d(input_size)

        self.lstm = nn.LSTM(
            input_size=input_size,
            hidden_size=hidden_size,
            num_layers=num_layers,
            batch_first=True,
            dropout=dropout if num_layers > 1 else 0,
            bidirectional=True,
        )

        self.dropout = nn.Dropout(dropout)
        self.fc1 = nn.Linear(hidden_size * 2, hidden_size)
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(hidden_size, num_class)

    def forward(self, x):
        N, C, T, V, M = x.size()

        x = x[:, :, :, :, 0]
        x = x.permute(0, 2, 3, 1)
        x = x.reshape(N, T, V * C)

        x = x.permute(0, 2, 1)
        x = self.bn_input(x)
        x = x.permute(0, 2, 1)

        _, (h_n, _) = self.lstm(x)

        h_forward = h_n[-2, :, :]
        h_backward = h_n[-1, :, :]
        hidden = torch.cat([h_forward, h_backward], dim=1)

        x = self.dropout(hidden)
        x = self.fc1(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc2(x)

        return x


class SkeletonLSTMLight(nn.Module):
    def __init__(
        self, num_class=2, in_channels=3, num_joints=33, hidden_size=64, dropout=0.2
    ):
        super().__init__()

        input_size = num_joints * in_channels

        self.lstm = nn.LSTM(
            input_size=input_size,
            hidden_size=hidden_size,
            num_layers=1,
            batch_first=True,
            bidirectional=True,
        )

        self.dropout = nn.Dropout(dropout)
        self.fc = nn.Linear(hidden_size * 2, num_class)

    def forward(self, x):
        N, C, T, V, _ = x.size()

        x = x[:, :, :, :, 0]
        x = x.permute(0, 2, 3, 1)
        x = x.reshape(N, T, V * C)

        lstm_out, _ = self.lstm(x)

        hidden = lstm_out.mean(dim=1)

        x = self.dropout(hidden)
        x = self.fc(x)

        return x


Model = SkeletonLSTMLight
