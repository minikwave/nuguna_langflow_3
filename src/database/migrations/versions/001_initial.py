from alembic import op
import sqlalchemy as sa

def upgrade():
    # 평가 결과 테이블
    op.create_table(
        'evaluation_results',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('prompt', sa.Text(), nullable=False),
        sa.Column('generated_sql', sa.Text()),
        sa.Column('expected_sql', sa.Text()),
        sa.Column('execution_time', sa.Float()),
        sa.Column('sql_accuracy', sa.Float()),
        sa.Column('test_results', sa.Text()),
        sa.Column('error', sa.Text()),
        sa.Column('timestamp', sa.DateTime()),
        sa.PrimaryKeyConstraint('id')
    )

    # 사용자 테이블
    op.create_table(
        'users',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('email', sa.String(length=120), nullable=False),
        sa.Column('password_hash', sa.String(length=128)),
        sa.Column('api_key', sa.String(length=64)),
        sa.Column('created_at', sa.DateTime()),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('email')
    )

def downgrade():
    op.drop_table('evaluation_results')
    op.drop_table('users') 